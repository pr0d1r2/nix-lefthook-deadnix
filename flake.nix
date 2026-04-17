{
  description = "Lefthook-compatible deadnix check";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nix-lefthook-nixfmt = {
      url = "github:pr0d1r2/nix-lefthook-nixfmt";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-shellcheck = {
      url = "github:pr0d1r2/nix-lefthook-shellcheck";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-lefthook-shfmt = {
      url = "github:pr0d1r2/nix-lefthook-shfmt";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-lefthook-nixfmt,
      nix-lefthook-shellcheck,
      nix-lefthook-shfmt,
    }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.writeShellApplication {
          name = "lefthook-deadnix";
          runtimeInputs = [ pkgs.deadnix ];
          text = builtins.readFile ./lefthook-deadnix.sh;
        };
      });

      devShells = forAllSystems (
        pkgs:
        let
          batsWithLibs = pkgs.bats.withLibraries (p: [
            p.bats-support
            p.bats-assert
            p.bats-file
          ]);
        in
        {
          default = pkgs.mkShell {
            packages = [
              self.packages.${pkgs.stdenv.hostPlatform.system}.default
              nix-lefthook-nixfmt.packages.${pkgs.stdenv.hostPlatform.system}.default
              nix-lefthook-shellcheck.packages.${pkgs.stdenv.hostPlatform.system}.default
              nix-lefthook-shfmt.packages.${pkgs.stdenv.hostPlatform.system}.default
              batsWithLibs
              pkgs.yamllint
              pkgs.git
              pkgs.lefthook
              pkgs.statix
              pkgs.deadnix
            ];
            shellHook = builtins.replaceStrings [ "@BATS_LIB_PATH@" ] [ "${batsWithLibs}" ] (
              builtins.readFile ./dev.sh
            );
          };
        }
      );
    };
}
