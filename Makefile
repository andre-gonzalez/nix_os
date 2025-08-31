any-install:
	sudo nix --extra-experimental-features flakes --extra-experimental-features nix-command run nixpkgs#nixos-anywhere -- --flake .#generic --generate-hardware-config nixos-generate-config ./hardware-configuration.nix --ssh-port 22 root@192.168.122.229	# nixos@192.168.10.125
