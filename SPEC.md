# SPEC — nix-lefthook-deadnix

## §G Goal

Lefthook-compatible [deadnix](https://github.com/astro/deadnix) wrapper. Filter `.nix` files from staged/pushed arguments and fail the commit when deadnix detects dead (unused) Nix code. Packaged as a Nix flake (`writeShellApplication`). Consumable either as a lefthook remote (`lefthook-remote.yml`, no flake input required) or as a flake input exposing `packages.${system}.default`. Opensource-safe: zero credentials, zero local paths, zero private refs.

## §C Constraints

- C1: Pure bash — no Python/Ruby/etc runtime deps; only `deadnix` on PATH
- C2: Nix flake — `writeShellApplication` pkg; devShells via plain `mkShell` (no `nix-dev-shell-agentic` input)
- C3: MIT license
- C4: Multi-platform: `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux`, `aarch64-linux`
- C5: Detached from parent project — no credential leaks, no hardcoded local paths, no private repo refs
- C6: All config via env vars — no config files beyond baseline (`config/lefthook/file_size_limits.yml`)
- C7: Exit non-zero on dead-code findings — hard enforcement, blocks commit
- C8: Self-lints with raw `deadnix --fail` and `statix check` in its own `lefthook.yml` (not the flake-wrapped variants) to avoid the circular flake dependency between this repo and the nix-check repos

## §I Interfaces

- I.cli: `lefthook-deadnix FILE...` — main binary; filters args to existing `*.nix` files, runs `deadnix --fail` per file, exit 1 if any file has dead code, exit 0 otherwise (including no args / no `.nix` files)
- I.env: `LEFTHOOK_DEADNIX_TIMEOUT` (seconds, default `30`) — wraps the hook invocation in `timeout`
- I.remote: `lefthook-remote.yml` — consumers add as a lefthook remote; defines `pre-commit` + `pre-push` `deadnix` commands (`glob: "*.nix"`, run `lefthook-deadnix {staged_files}` / `{push_files}`)
- I.flake: `packages.${system}.default` — the `lefthook-deadnix` pkg
- I.devshell: `devShells.${system}.default` + `.#ci` — plain `mkShell`s; `ci` exports `BATS_LIB_PATH`, `default` additionally runs `dev.sh` as `shellHook`
- I.ci: `.github/workflows/ci.yml` — linux + macos via `pr0d1r2/nix-lefthook-ci-action`

## §V Invariants

- V1: No args → exit 0; no existing `*.nix` files among args → exit 0 (silent, no crash)
- V2: Non-existent paths are skipped silently (`[ -f "$f" ]` guard)
- V3: Only `*.nix` files are checked; all other extensions filtered out of mixed input
- V4: Clean `.nix` file → exit 0; any file with dead code → exit 1 (aggregated across all files via `status`)
- V5: Exit code is hard — a dead-code finding blocks the commit (C7)
- V6: `LEFTHOOK_DEADNIX_TIMEOUT` bounds the hook; default `30`s applied via `timeout ${LEFTHOOK_DEADNIX_TIMEOUT:-30}`
- V7: `packages.${system}.default` set on all four supported systems; built from `./lefthook-deadnix.sh` with `pkgs.deadnix` as the sole runtime input
- V8: `flake.nix` has no `nix-dev-shell-agentic` input — devShells are plain `mkShell`; sibling lefthook wrappers enter the shell via 13 `flake = false` `-src` inputs, keeping the lock free of any flake dep-tree explosion
- V9: This repo IS deadnix, so its own `lefthook.yml` uses raw `deadnix --fail` (C8); the `-src` leaves cover the *other* remotes the CI shell must run (including `statix`), not a deadnix wrapper
- V10: `dev.sh` exports `BATS_LIB_PATH` from the `@BATS_LIB_PATH@` placeholder and runs `lefthook install` when `.git/hooks/pre-commit` is absent
- V11: CI runs lefthook pre-commit + pre-push on linux + macos via the shared ci-action
- V12: No credentials, secrets, tokens, API keys, or private paths in any tracked file
- V13: No hardcoded local filesystem paths (enforced by `nix-lefthook-git-no-local-paths` remote)
- V14: All linters pass: nixfmt, shellcheck, shfmt, statix, deadnix, yamllint, typos, editorconfig-checker, bats-parse, bats-unit, trailing-whitespace, missing-final-newline, git-conflict-markers, git-no-local-paths, file-size-check, nix-flake-check
- V15: `config/lefthook/file_size_limits.yml` raises the `nix` cap to `10240` — the flake.nix with 13 inline wrappers exceeds the 4096 default

## §T Tasks

| id | status | task | cites |
| --- | --- | --- | --- |
| T1 | x | core wrapper: filter `*.nix`, `deadnix --fail` per file, aggregate exit 1 on findings | V1,V2,V3,V4,V5,I.cli |
| T2 | x | timeout env knob `LEFTHOOK_DEADNIX_TIMEOUT` wired in lefthook configs | V6,I.env |
| T3 | x | Nix flake pkg (`writeShellApplication`, runtimeInputs=[deadnix]) | C1,C2,V7,I.flake |
| T4 | x | flatten flake: drop `nix-dev-shell-agentic`, plain `mkShell` + 13 `-src` leaves | V8,V9,C2 |
| T5 | x | devShells default + ci, BATS_LIB_PATH, dev.sh shellHook | V10,I.devshell |
| T6 | x | lefthook-remote.yml: pre-commit + pre-push deadnix commands for consumers | I.remote |
| T7 | x | dev.sh — BATS_LIB_PATH export + lefthook auto-install | V10 |
| T8 | x | unit tests: lefthook-deadnix.bats (6 tests, assert_failure on dead code) | V1,V2,V3,V4 |
| T9 | x | unit tests: dev.bats (3 tests) | V10 |
| T10 | x | self-lint via raw `deadnix --fail` + `statix check` (circular-dep avoidance) | C8,V9 |
| T11 | x | linter suite via lefthook remotes | V14 |
| T12 | x | GitHub Actions CI: linux + macos via nix-lefthook-ci-action | V11,I.ci |
| T13 | — | ~~update-pins.yml~~: dropped — pin refresh handled by loop | — |
| T14 | x | config/lefthook/file_size_limits.yml: raise nix cap to 10240 | V15,C6 |
| T15 | x | opensource audit: no credentials/local-paths/private-refs in any tracked file | V12,V13,C5 |
