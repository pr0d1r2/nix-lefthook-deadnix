# nix-lefthook-deadnix

<!-- hallucinogen:autonomy-disclaimer start -->
> Read [LLM-DISCLAIMER](docs/LLM-DISCLAIMER.md) first. This repository is
> tended by an autonomous loop, and that file says what the loop may do here,
> what it may not, and what to check before trusting anything in this tree.
<!-- hallucinogen:autonomy-disclaimer end -->

[![CI](https://github.com/pr0d1r2/nix-lefthook-deadnix/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0d1r2/nix-lefthook-deadnix/actions/workflows/ci.yml) [![NixOS 26.05](https://img.shields.io/badge/NixOS-26.05-blue.svg?logo=nixos)](https://nixos.org)

> This code is LLM-generated and validated through an automated integration process using [lefthook](https://github.com/evilmartians/lefthook) git hooks, [bats](https://github.com/bats-core/bats-core) unit tests, and GitHub Actions CI.

Lefthook-compatible [deadnix](https://github.com/astro/deadnix) wrapper, packaged as a Nix flake.

Filters `.nix` files from staged arguments and checks for unused code. Exits 0 when no matching files are found.

## Architecture

```mermaid
flowchart LR
  consumer["consumer lefthook.yml"] -->|"remotes"| remote["lefthook-remote.yml"]
  remote -->|"pre-commit: *.nix → {staged_files}"| lefthook_deadnix["lefthook-deadnix"]
  remote -->|"pre-push: *.nix → {push_files}"| lefthook_deadnix["lefthook-deadnix"]
  lefthook_deadnix -->|"runs"| tool["deadnix"]
  lefthook_deadnix -->|"exit status"| consumer
```

## Usage

### Option A: Lefthook remote (recommended)

Add to your `lefthook.yml` — no flake input needed, just `pkgs.deadnix` in your devShell:

```yaml
remotes:
  - git_url: https://github.com/pr0d1r2/nix-lefthook-deadnix
    ref: main
    configs:
      - lefthook-remote.yml
```

### Option B: Flake input

Add as a flake input:

```nix
inputs.nix-lefthook-deadnix = {
  url = "github:pr0d1r2/nix-lefthook-deadnix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Add to your devShell:

```nix
nix-lefthook-deadnix.packages.${pkgs.stdenv.hostPlatform.system}.default
```

Add to `lefthook.yml`:

```yaml
pre-commit:
  commands:
    deadnix:
      glob: "*.nix"
      run: timeout ${LEFTHOOK_DEADNIX_TIMEOUT:-30} lefthook-deadnix {staged_files}
```

## Self-linting

> **Note:** This repo uses raw `statix check` and `deadnix --fail` commands
> in its own lefthook config instead of the flake-wrapped versions. This
> avoids circular flake dependencies — the nix-check repos and the base
> linter repos form a dependency cycle if they reference each other as flake
> inputs. Leaf repos that consume these checks do not have this limitation
> and use the wrapped versions normally.

### Configuring timeout

The default timeout is 30 seconds. Override per-repo via environment variable:

```bash
export LEFTHOOK_DEADNIX_TIMEOUT=60
```

## Development

The repo includes an `.envrc` for [direnv](https://direnv.net/) — entering the directory automatically loads the devShell with all dependencies:

```bash
cd nix-lefthook-deadnix  # direnv loads the flake
bats tests/unit/
```

If not using direnv, enter the shell manually:

```bash
nix develop
bats tests/unit/
```

### Development architecture

```mermaid
flowchart LR
  envrc[".envrc"] -->|"use flake"| flake["flake.nix"]
  flake -->|"mkConsumerFlake"| sas["set-and-setting"]
  flake -->|"devShell"| shell["dev shell"]
  shell -->|"on entry"| devsh["dev.sh"]
  sas -->|"assembled hooks"| lh["lefthook.yml"]
  lh -->|"pre-commit / pre-push"| checks["linters, bats, nix flake check"]
  ci[".github/workflows/ci.yml"] -->|"guardrails.yml"| checks
```

## License

MIT
