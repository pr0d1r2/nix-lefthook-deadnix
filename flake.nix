{
  description = "CHANGEME";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs-lock.url = "github:pr0d1r2/nixpkgs-lock";
    nixpkgs.follows = "nixpkgs-lock/nixpkgs";

    set-and-setting = {
      url = "github:pr0d1r2/set-and-setting";
      inputs.nixpkgs-lock.follows = "nixpkgs-lock";
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
          actionlint = pkgs.actionlint;
          "lefthook-actionlint" = pkgs.writeShellApplication {
            name = "lefthook-actionlint";
            runtimeInputs = [ pkgs.actionlint ];
            text = ''
              actionlint "$@"
            '';
          };
      };
      src = ./.;
    }
    // {
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
                      self.packages.${system}.lefthook-actionlint
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
