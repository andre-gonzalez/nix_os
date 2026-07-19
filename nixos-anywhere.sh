nix run github:nix-community/nixos-anywhere -- \
         --generate-hardware-config nixos-generate-config \
           ./hosts/samsung-expert/hardware-configuration.nix \
         --flake .#samsung-expert \
         -i ~/.ssh/personal_id_ed25519_2023-11 \
         --ssh-port 1050 \
         --target-host root@192.168.100.68
