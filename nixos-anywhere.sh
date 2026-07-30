nix run github:nix-community/nixos-anywhere -- \
         --generate-hardware-config nixos-generate-config \
           ./hosts/samsung-expert/hardware-configuration.nix \
         --flake .#samsung-expert \
         --extra-files ./.extra-files/samsung-expert \
         -i ~/.ssh/personal_id_ed25519_2023-11 \
         --target-host root@192.168.10.108
