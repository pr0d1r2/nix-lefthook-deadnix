# shellcheck shell=bash
# Lefthook-compatible deadnix wrapper.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

if [ $# -eq 0 ]; then
    exit 0
fi

files=()
for f in "$@"; do
    [ -f "$f" ] || continue
    case "$f" in
        *.nix) files+=("$f") ;;
    esac
done

if [ ${#files[@]} -eq 0 ]; then
    exit 0
fi

status=0
for f in "${files[@]}"; do
    if ! deadnix --fail "$f"; then
        status=1
    fi
done
exit "$status"
