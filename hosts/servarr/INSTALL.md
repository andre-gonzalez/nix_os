# servarr: install on a new Proxmox VM and cut over from Debian

The Debian VM keeps running until the cutover (section 5) and stays on disk as
the fallback (section 6). Placeholders: `<debian-id>` / `<nixos-id>` are the
Proxmox VM IDs, `<temp-ip>` the new VM's temporary LAN address, `<ssh-port>`
the SSH port (`secrets/ssh-port.age`, same as Debian's).

What moves from Debian, and how:

| What | How |
|------|-----|
| SSH host key | `.extra-files/servarr`, injected by nixos-anywhere. GitHub Actions' pinned `DEPLOY_KNOWN_HOSTS` and agenix both keep working |
| `/opt/servarr/.env`, GitHub read key, Radicale mirror key, TOTP seed | agenix (`secrets/servarr-*.age`) |
| CI login key (public) | `hosts/servarr/ci-deploy-key.pub` |
| `/opt/servarr` checkout | fresh clone of `main` on first boot (`servarr-checkout.service`) |
| `/srv/servarr` (all service data) | rsync, once ahead of time and once at cutover |
| Tailscale identity (name `servarr`, its 100.x IP) | `/var/lib/tailscale` copied at cutover |
| LAN IP (Pi-hole's address) | DHCP reservation: the new VM takes Debian's MAC at cutover |
| iGPU (Jellyfin QuickSync) | Proxmox `hostpci`, moved at cutover |

## 1. Secrets (laptop)

```bash
secrets/import-from-servarr.sh     # one TOTP code, then frank's sudo password on Debian
git status                          # new secrets/servarr-*.age, hosts/servarr/ci-deploy-key.pub
git commit -m "servarr: import secrets from Debian"
```

It also writes `.extra-files/servarr/etc/ssh/ssh_host_ed25519_key` (gitignored)
and checks that it matches the `servarr` key in `secrets/secrets.nix`. Keep an
off-machine copy of that key: agenix cannot decrypt anything on servarr without it.

## 2. The VM (Proxmox)

Create it next to Debian, with Debian's CPU/RAM and the same bridge:

- Machine `q35`, BIOS **OVMF (UEFI)** with an EFI disk, **pre-enrolled keys off**
  (no Secure Boot)
- Disk on **VirtIO SCSI single** (it appears as `/dev/sda`, which disko erases), at
  least as large as Debian's root
- QEMU guest agent on, **no `hostpci` yet** (the iGPU stays with Debian)

Boot the NixOS minimal installer ISO, then on its console `sudo passwd root`
and, from the laptop, `ssh-copy-id -i ~/.ssh/personal_id_ed25519_2023-11 root@<temp-ip>`.

## 3. Install (laptop)

```bash
TARGET=<temp-ip> ./nixos-anywhere-servarr.sh
git add hosts/servarr/hardware-configuration.nix   # the real scan, written in place
git commit -m "servarr: hardware-configuration from the VM"
```

Detach the ISO; the VM reboots into NixOS.

### First-boot checks

`ssh -p <ssh-port> frank@<temp-ip>` asks for the key and a TOTP code, as on
Debian. If SSH fails, the Proxmox console logs in with frank's password.

```bash
systemctl --failed                          # nothing
findmnt /mnt/media                          # NFS from the NAS
docker info >/dev/null && echo docker ok
systemctl status servarr-checkout           # cloned main into /opt/servarr
ls -l /opt/servarr/.env                     # -> /run/agenix/servarr-env
ss -lntup | grep ':53 '                     # nothing: resolved's stub is off
sudo -u deploy env DEPLOY_GITHUB_KEY=/run/agenix/servarr-github-read \
    /opt/servarr/ci/deploy.sh check         # every line ok
cd /opt/servarr && for s in stacks/*/; do ci/dc "$(basename "$s")" config -q || echo "^ $s"; done
tailscale status --self                     # joined as servarr-1 (Debian still holds "servarr")
```

If `tailscale-authkey.age` has expired, join by hand:
`sudo tailscale up --hostname servarr-nixos`.

## 4. Pre-seed and smoke test

Copy the data while Debian keeps serving. From the laptop, with agent
forwarding, log in to Debian and push to the new VM (root on Debian reads
everything; frank on NixOS may run rsync as root without a password,
`base/users.nix`):

```bash
ssh -A servarr
sudo SSH_AUTH_SOCK="$SSH_AUTH_SOCK" rsync -aHAX --numeric-ids --delete --info=progress2 \
    -e "ssh -p <ssh-port> -o StrictHostKeyChecking=accept-new" \
    --rsync-path="sudo /run/current-system/sw/bin/rsync" \
    /srv/servarr/ frank@<temp-ip>:/srv/servarr/
```

The inner ssh asks for the new VM's TOTP code. (If Debian refuses agent
forwarding, put a throwaway key in frank's `~/.ssh/authorized_keys` on the new
VM for the migration and delete it afterwards.)

On the new VM, pull every image now so the cutover does not wait for them, then
start only the stacks that do **not** touch `/mnt/media`. A second Sonarr,
Radarr or qBittorrent on the same NFS library would grab, move and delete the
same files as Debian's.

```bash
cd /opt/servarr
for s in dns grocy radicale media rss; do ci/dc $s pull; done
for s in dns grocy radicale; do ci/dc $s up -d; done
docker ps                                   # pihole healthy, radicale healthy
dig +short example.org @127.0.0.1           # Pi-hole -> Unbound answers
for s in dns grocy radicale; do ci/dc $s stop; done
```

## 5. Cutover

Downtime: from step 2 to step 7, mostly the final rsync.

Do steps 2–4 in an SSH session to Debian's **LAN** address
(`ssh -A -p <ssh-port> frank@<lan-ip>`), not `ssh servarr`: that name goes over
Tailscale, which step 4 stops on Debian.

1. **Freeze deploys** (laptop): `gh variable set DEPLOY_MODE --body off -R andre-gonzalez/servarr`.
   Merge nothing until step 9, Renovate PRs included.
2. **Stop Debian's stacks** (on Debian):
   ```bash
   cd /opt/servarr && for s in stacks/*/; do ci/dc "$(basename "$s")" stop; done
   sudo systemctl disable --now docker.service docker.socket radicale-git-push.timer
   ```
3. **Final rsync**: the command from section 4 again.
4. **Tailscale identity**. On the new VM: `sudo systemctl stop tailscaled`. On Debian:
   ```bash
   sudo systemctl disable --now tailscaled
   sudo SSH_AUTH_SOCK="$SSH_AUTH_SOCK" rsync -aHAX --numeric-ids --delete \
       -e "ssh -p <ssh-port>" --rsync-path="sudo /run/current-system/sw/bin/rsync" \
       /var/lib/tailscale/ frank@<temp-ip>:/var/lib/tailscale/
   sudo poweroff
   ```
   Then `sudo poweroff` the new VM too.
5. **Proxmox**: note Debian's MAC and iGPU line, hand both to the new VM:
   ```bash
   qm config <debian-id> | grep -E '^(net0|hostpci)'
   qm set <debian-id> --onboot 0 --delete hostpci0
   qm set <debian-id> --net0 virtio,bridge=<bridge>                  # fresh MAC, no clash
   qm set <nixos-id>  --net0 virtio=<debian-mac>,bridge=<bridge> \
                      --hostpci0 <debian's hostpci0 value> --onboot 1
   qm start <nixos-id>
   ```
6. **Verify the host**: `ssh servarr` from the laptop works with no host-key
   warning (same key, same name). Then on it: `ip -br addr` (Debian's LAN IP),
   `tailscale status --self` (`servarr`, Debian's 100.x IP), `ls /dev/dri`
   (`card*`, `renderD128`), `systemctl --failed`.
7. **Start the stacks** — the ones Debian ran; home-assistant was never started:
   ```bash
   cd /opt/servarr && for s in dns grocy radicale rss media; do ci/dc $s up -d; done
   docker ps --format '{{.Names}}\t{{.Status}}'
   ```
   From a LAN client: `dig example.org @<lan-ip>`. Play something in Jellyfin
   that needs a transcode and check the dashboard shows hardware (VAAPI/QSV).
8. **Radicale mirror**: the collections repo came from Debian with
   `core.sshCommand` naming `~/.ssh/radicale_deploy`. Point it at the agenix key
   (the timer sets its own, this is for pushes by hand), then push once:
   ```bash
   git -C /srv/servarr/radicale/collections config core.sshCommand \
       "ssh -i /run/agenix/servarr-radicale-deploy -o IdentitiesOnly=yes -o ConnectTimeout=10"
   sudo systemctl start radicale-git-push && systemctl status radicale-git-push
   ```
9. **Re-enable deploys** (laptop):
   ```bash
   gh variable set DEPLOY_MODE --body dry-run -R andre-gonzalez/servarr
   gh workflow run ci-cd.yaml -R andre-gonzalez/servarr --ref main   # read the job summary
   gh variable set DEPLOY_MODE --body live -R andre-gonzalez/servarr
   ```
10. Tailscale admin console: delete the temporary `servarr-1` / `servarr-nixos` node.

## 6. Fallback to Debian

Until the stacks on NixOS have written data you want to keep (step 7), going
back is safe: power the NixOS VM off, give it a fresh MAC and take its
`hostpci0`, give `hostpci0` and `--onboot 1` back to Debian, start Debian, then
`sudo systemctl enable --now tailscaled docker.socket docker.service
radicale-git-push.timer` and `ci/dc <stack> up -d`. Its `/srv/servarr` and
`/var/lib/tailscale` were copied, never moved, so they are as they were at
step 3. After step 7, rsync `/srv/servarr` back first.

Never run both VMs with the same Tailscale state or the same MAC.

Keep the Debian VM (powered off, `onboot 0`) for a few weeks before deleting it.

## Operating it

- **NixOS changes**: until the nix_os CI deploys it, from the laptop:
  `nixos-rebuild switch --flake .#servarr --target-host frank@servarr --sudo --ask-sudo-password`
  (TOTP, then frank's sudo password). Docker runs with live-restore, so a
  switch that restarts dockerd leaves the containers up.
- **New `${VAR}` in a servarr compose file**: add it to `secrets/servarr-env.age`
  (in `secrets/`: `nix run github:ryantm/agenix -- -e servarr-env.age -i ~/.ssh/personal_id_ed25519_2023-11`),
  deploy this host, and only then merge
  the servarr PR — its deploy refuses a variable the server's `.env` lacks.
- **New service data dir**: `mkdir /srv/servarr/<service>` on the server before
  merging, as before. NixOS creates only `/srv/servarr` itself.
- **NAS down at boot**: docker requires `/mnt/media` (`storage.nix`), so no
  container starts — Pi-hole included — until the mount works:
  `sudo systemctl restart mnt-media.mount docker.service`.
