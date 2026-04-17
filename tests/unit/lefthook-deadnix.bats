#!/usr/bin/env bats

setup() {
    load "$BATS_LIB_PATH/bats-support/load"
    load "$BATS_LIB_PATH/bats-assert/load"
    load "$BATS_LIB_PATH/bats-file/load"

    TEST_TEMP="$(mktemp -d)"
}

teardown() {
    rm -rf "$TEST_TEMP"
}

@test "exits 0 with no arguments" {
    run lefthook-deadnix
    assert_success
}

@test "exits 0 when no .nix files in arguments" {
    touch "$TEST_TEMP/file.txt"
    run lefthook-deadnix "$TEST_TEMP/file.txt"
    assert_success
}

@test "skips missing files silently" {
    run lefthook-deadnix "/nonexistent/file.nix"
    assert_success
}

@test "accepts nix file with no dead code" {
    cat > "$TEST_TEMP/good.nix" << 'EOF'
{ pkgs }:
pkgs.hello
EOF
    run lefthook-deadnix "$TEST_TEMP/good.nix"
    assert_success
}

@test "detects unused bindings" {
    cat > "$TEST_TEMP/bad.nix" << 'EOF'
let
  unused = 42;
in
  "hello"
EOF
    run lefthook-deadnix "$TEST_TEMP/bad.nix"
    assert_failure
}

@test "filters non-.nix files from mixed input" {
    cat > "$TEST_TEMP/good.nix" << 'EOF'
{ pkgs }:
pkgs.hello
EOF
    touch "$TEST_TEMP/file.txt"
    run lefthook-deadnix "$TEST_TEMP/good.nix" "$TEST_TEMP/file.txt"
    assert_success
}
