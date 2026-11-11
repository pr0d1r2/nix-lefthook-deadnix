# Changelog

All notable changes to this project are documented here.

## Unreleased

- Refresh `nixpkgs-lock` in `flake.lock` (nixpkgs `ac588ef`). Ruby is still
  3.4.11 there (CVE-2026-97229, fixed in 3.4.12), pending the nixpkgs-lock#94
  backport; this project is pure bash and ships no ruby.

- Pin the reusable guardrails workflow in CI to a full commit SHA (`ci-lint-sha`).

- Use the standard `confirm` app instead of a local copy that omitted the
  auto-detected `actions` and `bats` fragment wrappers.
