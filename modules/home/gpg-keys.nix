# GPG secret keys restored on every machine — read by home/gpg.nix and by
# secrets/export-gpg-keys.sh (keep the Ansible copy in
# roles/light_workstation/defaults/main.yml in sync). Fingerprints are public.
[
  "546B690A34BFB5F67D768159BB1AC653FDBAD33C" # André Gonzalez (personal) <lopescg@gmail.com>
  # Not the Athenaworks key (A2F88C89…BE5ED78E): its passphrase is lost, so it
  # cannot be exported; it only matters for a former employer's data.
]
