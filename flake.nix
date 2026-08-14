{
  description = "CHANGEME";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    # Keep the pinned actionlint check compatible with sourceByRegex in
    # nixpkgs 25.11 (the 26.05 API requires a list of regexes, while the
    # shared check framework passes one regex).
    nixpkgs.url = "github:NixOS/nixpkgs/b6018f87da91d19d0ab4cf979885689b469cdd41";

    set-and-setting = {
      url = "github:pr0d1r2/set-and-setting";
      inputs.nixpkgs-lock.follows = "nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      set-and-setting,
      ...
    }:
    set-and-setting.lib.mkConsumerFlake {
      inherit self nixpkgs set-and-setting;
      fragments = [
        "base"
        "nix"
        "shell"
        "ascii"
        "markdown"
        "yaml"
      ];
      extraPackages = pkgs: {
        default = pkgs.writeShellApplication {
          name = "lefthook-deadnix";
          runtimeInputs = [ pkgs.deadnix ];
          text = builtins.readFile ./lefthook-deadnix.sh;
        };
      };
      src = ./.;
    }
    // {
      checks =
        nixpkgs.lib.recursiveUpdate
          (set-and-setting.lib.mkConsumerFlake {
            inherit self nixpkgs set-and-setting;
            fragments = [
              "base"
              "nix"
              "shell"
              "ascii"
              "markdown"
              "yaml"
            ];
            extraPackages = pkgs: {
              default = pkgs.writeShellApplication {
                name = "lefthook-deadnix";
                runtimeInputs = [ pkgs.deadnix ];
                text = builtins.readFile ./lefthook-deadnix.sh;
              };
            };
            src = ./.;
          }).checks
          (
            nixpkgs.lib.mapAttrs
              (system: _: {
                actionlint =
                  nixpkgs.legacyPackages.${system}.runCommand "actionlint-check"
                    { nativeBuildInputs = [ nixpkgs.legacyPackages.${system}.actionlint ]; }
                    ''
                      cd ${./.}
                      actionlint $(find .github/workflows -type f \( -name '*.yml' -o -name '*.yaml' \) -print)
                      touch $out
                    '';
              })
              (nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ] (_: null))
          );
      apps =
        nixpkgs.lib.mapAttrs
          (
            system: apps:
            apps
            // {
              confirm =
                let
                  pkgs = nixpkgs.legacyPackages.${system};
                  materialization = set-and-setting.lib.materializationFor {
                    inherit pkgs;
                    fragments = [
                      "base"
                      "actions"
                      "nix"
                      "shell"
                      "ascii"
                      "markdown"
                      "yaml"
                    ];
                  };
                  confirm = pkgs.writeShellApplication {
                    name = "confirm";
                    runtimeInputs = [
                      pkgs.coreutils
                      pkgs.diffutils
                      pkgs.findutils
                      pkgs.gawk
                      pkgs.git
                      pkgs.gnugrep
                    ]
                    ++ materialization.packages;
                    runtimeEnv = {
                      FRAGMENTS_DIR = "${set-and-setting}/setting/integrations/lefthook";
                      ASSEMBLE_SCRIPT = "${set-and-setting}/setting/lib/assemble-lefthook.sh";
                      DETECT_SCRIPT = "${set-and-setting}/setting/lib/detect-fragments.sh";
                      SETTING_SRC = "${self.packages.${system}.setting}";
                      CONFIRM_SCRIPT = "${set-and-setting}/lib/confirm.sh";
                      CONFIRM_REV = set-and-setting.rev or "unknown";
                    };
                    text = builtins.readFile ./confirm.sh;
                  };
                in
                {
                  type = "app";
                  program = "${confirm}/bin/confirm";
                };
            }
          )
          (set-and-setting.lib.mkConsumerFlake {
            inherit self nixpkgs set-and-setting;
            fragments = [
              "base"
              "nix"
              "shell"
              "ascii"
              "markdown"
              "yaml"
            ];
            extraPackages = pkgs: {
              default = pkgs.writeShellApplication {
                name = "lefthook-deadnix";
                runtimeInputs = [ pkgs.deadnix ];
                text = builtins.readFile ./lefthook-deadnix.sh;
              };
            };
            src = ./.;
          }).apps;
    };
}
