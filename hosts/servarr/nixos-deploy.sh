# servarr-nixos-deploy — move servarr to one commit of nix_os main, from CI.
#
# GitHub Actions logs in as `nixdeploy`, whose key and Match block force
#   sudo servarr-nixos-deploy "$SSH_ORIGINAL_COMMAND"
# so the client can only *name* a commit; this script, as root, does the rest:
#
#   deploy <40-hex sha> [--dry-run]
#       1 the sha must be on main of the public repo (fetched here, by URL)
#       2 build its servarr system here (cache.nixos.org substitutes most)
#       3 unchanged closure -> record it, done (exit 0); --dry-run stops here
#       4 arm a revert timer (@revertAfter@), then switch-to-configuration
#         TEST: active now, but the boot default is still the old generation
#       5 health: @healthUnits@ active, or revert now
#       6 exit 4 — CI must come back and confirm
#   confirm <sha>
#       a NEW connection proves sshd, the firewall and Tailscale still work;
#       disarm the timer, make the generation the boot default
#   revert       what the timer runs; also usable by hand
#   status
#
# If CI never confirms (the new config cut it off), the timer switches back.
# deploy/confirm/revert run in a transient systemd unit, so a connection that
# drops mid-activation (sshd or tailscaled restarting) cannot kill them.
#
# Output goes to a PUBLIC Actions log: only shas, store paths and unit names.
# Build and activation output stays in /var/lib/nixos-deploy/*.log.
#
# Exit codes: 0 done / nothing to do, 1 failed and reverted, 2 refused
# (nothing changed), 3 revert failed too (needs a human), 4 activated,
# waiting for confirm.

STATE=/var/lib/nixos-deploy
REPO_URL=@repoUrl@
ATTR=@attr@
REVERT_AFTER=@revertAfter@
HEALTH_UNITS=(@healthUnits@)
REVERT_UNIT=nixos-deploy-revert
SELF=$(readlink -f "$0")

say() {
	printf '%s\n' "$*"
	printf '%s %s\n' "$(date -Is)" "$*" >>"$STATE/deploy.log"
}
refuse() {
	say "refused: $*"
	exit 2
}
usage() {
	printf '%s\n' "usage: deploy <sha> [--dry-run] | confirm <sha> | revert | status" >&2
	exit 2
}

# The whole client command arrives as one argument; split it, never eval it.
read -r -a words <<<"${1:-}"
[ "${#words[@]}" -le 3 ] || usage
cmd=${words[0]:-}
sha=${words[1]:-}
flag=${words[2]:-}

valid_sha() { [[ $sha =~ ^[0-9a-f]{40}$ ]] || usage; }

case $cmd in
deploy | confirm | revert)
	if [ -z "${NIXOS_DEPLOY_UNIT:-}" ]; then
		exec systemd-run --quiet --wait --pipe --collect \
			--unit="nixos-deploy-$cmd-$$" --setenv=NIXOS_DEPLOY_UNIT=1 \
			"$SELF" "${1:-}"
	fi
	;;
status) ;;
*) usage ;;
esac

install -d -m 700 "$STATE"
exec 9>"$STATE/lock"
flock -w 600 9 || refuse "another deploy held the lock for 600s"

current=$(cat "$STATE/current" 2>/dev/null || true)

fetch_main() {
	local repo=$STATE/nix_os.git
	[ -d "$repo" ] || git init --quiet --bare "$repo"
	git -C "$repo" fetch --quiet "$REPO_URL" "+refs/heads/main:refs/remotes/origin/main"
}
on_main() {
	local repo=$STATE/nix_os.git
	git -C "$repo" cat-file -e "$1^{commit}" 2>/dev/null &&
		git -C "$repo" merge-base --is-ancestor "$1" refs/remotes/origin/main
}
not_newer() { # $1 is $2 or an ancestor of it
	[ -n "$2" ] && git -C "$STATE/nix_os.git" merge-base --is-ancestor "$1" "$2" 2>/dev/null
}

arm_revert() {
	systemctl stop "$REVERT_UNIT.timer" 2>/dev/null || true
	systemd-run --quiet --unit="$REVERT_UNIT" --on-active="$REVERT_AFTER" \
		--timer-property=AccuracySec=1s --timer-property=RemainAfterElapse=no \
		--setenv=NIXOS_DEPLOY_UNIT=1 "$SELF" revert
}
disarm_revert() {
	systemctl stop "$REVERT_UNIT.timer" 2>/dev/null || true
}

healthy() {
	local u waited=0 bad
	while :; do
		bad=()
		for u in "${HEALTH_UNITS[@]}"; do
			systemctl is-active --quiet "$u" || bad+=("$u")
		done
		[ "${#bad[@]}" -eq 0 ] && return 0
		if [ "$waited" -ge 60 ]; then
			say "not active after ${waited}s: ${bad[*]}"
			return 1
		fi
		sleep 5
		waited=$((waited + 5))
	done
}

# Back to the generation recorded in $STATE/pending. It is still the boot
# default (only `test` ran), so `test` again is enough.
revert_pending() {
	local psha new prev
	read -r psha new prev <"$STATE/pending"
	disarm_revert
	say "reverting $psha: back to $prev"
	if "$prev/bin/switch-to-configuration" test >>"$STATE/deploy.log" 2>&1 && healthy; then
		rm -f "$STATE/pending"
		say "reverted"
		return 0
	fi
	say "the revert did not come up clean: needs a human"
	return 1
}

case $cmd in
deploy)
	valid_sha
	case $flag in "" | --dry-run) ;; *) usage ;; esac
	if [ -e "$STATE/pending" ]; then
		refuse "$(cut -d' ' -f1 "$STATE/pending") is waiting for confirm (or the ${REVERT_AFTER} revert)"
	fi
	fetch_main || refuse "cannot fetch main from $REPO_URL"
	on_main "$sha" || refuse "$sha is not on main"
	if not_newer "$sha" "$current"; then
		say "nothing to do: $sha is already deployed (current: $current)"
		exit 0
	fi

	say "building $sha"
	new=$(nix build --no-link --print-out-paths \
		"git+$REPO_URL?ref=main&rev=$sha#nixosConfigurations.$ATTR.config.system.build.toplevel" \
		2>>"$STATE/build.log") || refuse "build failed (build.log on the server)"
	prev=$(readlink -f /run/current-system)
	if [ "$new" = "$prev" ]; then
		[ "$flag" = --dry-run ] || printf '%s\n' "$sha" >"$STATE/current"
		say "nothing to do: $sha does not change servarr ($new)"
		exit 0
	fi
	if [ "$flag" = --dry-run ]; then
		say "dry-run: would activate $new (running: $prev)"
		exit 0
	fi

	printf '%s %s %s\n' "$sha" "$new" "$prev" >"$STATE/pending"
	arm_revert
	say "activating $new (test; reverts in $REVERT_AFTER unless confirmed)"
	if "$new/bin/switch-to-configuration" test >>"$STATE/deploy.log" 2>&1 && healthy; then
		say "activated $sha: waiting for confirm"
		exit 4
	fi
	say "activation failed"
	revert_pending && exit 1
	exit 3
	;;

confirm)
	valid_sha
	if [ ! -e "$STATE/pending" ]; then
		[ "$current" = "$sha" ] && {
			say "already confirmed: $sha"
			exit 0
		}
		refuse "nothing is waiting for confirm (reverted already?)"
	fi
	read -r psha new _ <"$STATE/pending"
	[ "$psha" = "$sha" ] || refuse "waiting for confirm is $psha, not $sha"
	disarm_revert
	if [ "$(readlink -f /run/current-system)" != "$new" ]; then
		rm -f "$STATE/pending"
		say "too late: $sha was reverted already"
		exit 1
	fi
	nix-env --profile /nix/var/nix/profiles/system --set "$new"
	if ! "$new/bin/switch-to-configuration" boot >>"$STATE/deploy.log" 2>&1; then
		say "could not make $new the boot default: running it, needs a human"
		exit 3
	fi
	printf '%s\n' "$sha" >"$STATE/current"
	rm -f "$STATE/pending"
	say "confirmed $sha: $new is the boot default"
	;;

revert)
	if [ ! -e "$STATE/pending" ]; then
		say "nothing to revert"
		exit 0
	fi
	revert_pending || exit 3
	;;

status)
	printf 'current: %s\n' "${current:-none}"
	printf 'pending: %s\n' "$(cut -d' ' -f1 "$STATE/pending" 2>/dev/null || echo none)"
	printf 'running: %s\n' "$(readlink -f /run/current-system)"
	;;
esac
