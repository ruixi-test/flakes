{
  description = "Ruixi-rebirth's NixOS Configuration";

  outputs = inputs @ { self, ... }:
    let
      selfPkgs = import ./pkgs;
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      imports = [
        ./home/profiles
        ./hosts
        ./modules
      ] ++ [
        inputs.flake-root.flakeModule
        inputs.treefmt-nix.flakeModule
      ];
      flake = {
        overlays.default = selfPkgs.overlay;
      };
      perSystem = { config, pkgs, system, ... }:
        {
          # NOTE: These overlays apply to the Nix shell only. See `modules/nix.nix` for system overlays.
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              #inputs.foo.overlays.default
            ];
          };

          treefmt.config = {
            inherit (config.flake-root) projectRootFile;
            package = pkgs.treefmt;
            programs.nixpkgs-fmt.enable = true;
            programs.prettier.enable = true;
            programs.taplo.enable = true;
            programs.shfmt.enable = true;
          };

          devShells = {
            # run by `nix devlop` or `nix-shell`(legacy)
            # Temporarily enable experimental features, run by`nix develop --extra-experimental-features nix-command --extra-experimental-features flakes`
            default = pkgs.mkShell {
              nativeBuildInputs = with pkgs; [ git neovim sbctl just ];
              inputsFrom = [
                config.flake-root.devShell
              ];
            };
            # run by `nix develop .#<name>`
            # NOTE: Here are some of the steps I documented, see `https://github.com/Mic92/sops-nix` for more details
            # ```
            # mkdir -p ~/.config/sops/age
            # age-keygen -o ~/.config/sops/age/keys.txt
            # age-keygen -y ~/.config/sops/age/keys.txt
            # sudo mkdir -p /var/lib/sops-nix
            # sudo cp ~/.config/sops/age/keys.txt /var/lib/sops-nix/key.txt
            # nvim $FLAKE_ROOT/.sops.yaml
            # mkdir $FLAKE_ROOT/secrets
            # sops $FLAKE_ROOT/secrets/secrets.yaml
            # ```
            secret = with pkgs; mkShell {
              name = "secret";
              nativeBuildInputs = [ sops age neovim ssh-to-age ];
              shellHook = ''
                export $EDITOR=nvim
                export PS1="\[\e[0;31m\](Secret)\$ \[\e[m\]"
              '';
              inputsFrom = [
                config.flake-root.devShell
              ];
            };
          };
          # used by the `nix fmt` command
          formatter = config.treefmt.build.wrapper;
        };
    };

  inputs = {
    # update single input: `nix flake lock --update-input <name>`
    # update all inputs: `nix flake update`
    disko.url = "github:nix-community/disko";
    emanote.url = "github:srid/emanote";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-root.url = "github:srid/flake-root";
    hyprland = {
      url = "github:hyprwm/Hyprland?ref=v0.39.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hycov = {
      url = "github:DreamMaoMao/hycov";
      inputs.hyprland.follows = "hyprland";
    };
    hypreasymotion = {
      url = "github:DreamMaoMao/hyprland-easymotion";
      inputs.hyprland.follows = "hyprland";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprpicker.url = "github:hyprwm/hyprpicker";
    hypr-contrib.url = "github:hyprwm/contrib";
    impermanence.url = "github:nix-community/impermanence";
    lanzaboote = {
      #please read this doc -> https://github.com/nix-community/lanzaboote/blob/master/docs/QUICK_START.md 
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nvim-flake.url = "github:Ruixi-rebirth/nvim-flake";
    nur.url = "github:nix-community/NUR";
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    rust-overlay.url = "github:oxalica/rust-overlay";
    sops-nix.url = "github:Mic92/sops-nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
      "https://ruixi-rebirth.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "ruixi-rebirth.cachix.org-1:sWs3V+BlPi67MpNmP8K4zlA3jhPCAvsnLKi4uXsiLI4="
    ];
    trusted-users = [ "root" "@wheel" ];
  };
}
