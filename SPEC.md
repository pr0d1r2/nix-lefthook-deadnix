# Flatten SPEC — nix-lefthook-deadnix

## Goal

Remove the `nix-dev-shell-agentic` flake input (and its transitive explosion) from `flake.nix`, preserving the `lefthook-deadnix` package output and keeping CI (`nix develop .#ci` + remote lefthook hooks) and bats green.

## Before

- flake.lock: 59 nodes.
- Inputs: nixpkgs-lock, nixpkgs(follows), nix-dev-shell-agentic(flake).
- Outputs: packages.<sys>.default = lefthook-deadnix; devShells ci/default via nix-dev-shell-agentic.lib.mkShells.

## Consumption of the agentic devShell here

- `.envrc` = `use flake` → devShells.<sys>.default.
- CI enters `nix develop .#ci` and runs lefthook install / pre-commit / pre-push --all-files.
- lefthook.yml `remotes:` invoke wrapper binaries that must be on PATH in the ci shell: lefthook-{nixfmt,shellcheck,shfmt,statix,bats-unit,yamllint,typos,trailing-whitespace,missing-final-newline,git-conflict-markers,editorconfig-checker,git-no-local-paths,file-size-check}; bare `bats` (bats-parse), bare `nix flake check` (nix-flake-check); plus lefthook, git, coreutils, parallel, deadnix.
- bats unit tests need BATS_LIB_PATH + lefthook-deadnix on PATH.

## Changes

### Inputs

Remove nix-dev-shell-agentic. Add `flake = false` `-src` inputs for each sibling wrapper the remotes invoke (13 leaves), mirroring the proven statix template. Result inputs: nixpkgs-lock, nixpkgs(follows), + 13 flake=false leaves. No flake input means no dep-tree explosion. This repo IS deadnix, so the deadnix wrapper is built locally from `./lefthook-deadnix.sh`, not via a -src; statix is added as a -src leaf since its remote is invoked.

### packages (UNCHANGED logic)

packages.<sys>.default = writeShellApplication { name="lefthook-deadnix"; runtimeInputs=[pkgs.deadnix]; text=readFile ./lefthook-deadnix.sh; }.

### devShells (plain mkShell)

lefthookWrappersFor helper (copied from proven statix template: bats-unit + file-size-check get special multi-input handling, rest via `wrap`). Swap the deadnix-src wrapper for statix-src (this repo's own tool is deadnix; the remote it must run instead is statix). batsWithLibsFor helper. ciCommon = [self pkg, batsWithLibs, bats, coreutils, deadnix, git, lefthook, nix, parallel] ++ wrappers.

- ci = mkShell { packages = ciCommon; BATS_LIB_PATH = "${batsWithLibs}/share/bats"; }
- default = mkShell { packages = ciCommon; shellHook = dev.sh expanded; }

### Side changes required to land a flattened flake green

- config/lefthook/file_size_limits.yml: nix 4096 → 10240. The flattened flake.nix has 13 inline wrappers and exceeds 4096 bytes; the proven template repo uses nix:10240 for the same reason. Pure config, no logic.
- lefthook-deadnix.sh: reformat 4-space → 2-space. The upstream nix-lefthook-shfmt remote (ref: main) enforces `-i 2`. Whitespace-only; wrapper behavior identical. Applied via shfmt -i 2 -w.

## Validation gate (all must pass)

- nix flake check — PASS.
- nix flake show — packages.<sys>.default = lefthook-deadnix; devShells ci+default. UNCHANGED set.
- nix build .#default + smoke (no-arg → 0).
- bats tests/unit/ inside nix develop .#ci — PASS.
- lefthook run pre-commit --all-files inside .#ci — PASS.
- lock nodes << 59.

## Then

Branch flatten-drop-agentic, commit, push, DRAFT PR. Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
