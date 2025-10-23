{
  description = "config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = outputs@{ self, nix-darwin, nixpkgs }:

    let
      system = "aarch64-darwin";
      configuration = { config, pkgs, ... }:

        let
          env = pkgs.buildEnv {
            name = "system-apps";
            paths = config.environment.systemPackages;
            pathsToLink = "/Applications";
          };

        in {
          environment.systemPackages = [
            pkgs.neovim
            pkgs.tree
            pkgs.curl
            pkgs.wget
            pkgs.git
            pkgs.gcc
            pkgs.clang
            pkgs.rustup
            pkgs.go
            pkgs.perl
            pkgs.nodejs
            pkgs.htop
            pkgs.btop
            pkgs.fastfetch
            pkgs.gopls
            pkgs.typescript-language-server
            pkgs.bash
            pkgs.wezterm
            pkgs.nixd
            pkgs.nixfmt
          ];

          system.activationScripts.applications.text = pkgs.lib.mkForce ''
            echo "Setting up /Applications..." >&2
            rm -rf /Applications/NixApps
            mkdir -p /Applications/NixApps
            find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
            while read -r src; do
              app_name=$(basename "$src")
              echo "copying $src" >&2
              ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/NixApps/$app_name"
            done
          '';

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Enable alternative shell support in nix-darwin.
          programs.bash.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          nixpkgs.hostPlatform = system;
        };
    in {
      darwinConfigurations."mac" = nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [ configuration ];
      };
    };
}
