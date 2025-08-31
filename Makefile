any-install:
	sudo nix --extra-experimental-features flakes --extra-experimental-features nix-command run nixpkgs#nixos-anywhere -- --flake .#generic --generate-hardware-config nixos-generate-config ./hardware-configuration.nix --ssh-port 1050 -i ~/.ssh/personal_id_ed25519_2023-11 frank@debian-vm.ewe-musical.ts.net
