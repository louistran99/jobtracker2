#!/usr/bin/env bash
# Keeps agent skills model-agnostic.
#
# `.agents/skills/` is the single source of truth. Codex and Cursor read that
# folder natively; every other tool gets a relative symlink to it (listed in
# LINKS below). Linking Cursor too would make each skill appear twice there.
#
# Usage:
#   scripts/link-agent-skills.sh           create or repair the symlinks
#   scripts/link-agent-skills.sh --check   verify only; change nothing (used by `make lint`)
set -euo pipefail

SOURCE=".agents/skills"

# Tool link path (relative to the repo root). Add a line to support a new tool.
LINKS=(
    ".claude/skills" # Claude Code
)

mode="link"
case "${1:-}" in
    "") ;;
    --check) mode="check" ;;
    *)
        echo "usage: $0 [--check]" >&2
        exit 2
        ;;
esac

root="$(git rev-parse --show-toplevel)"
cd "$root"

failures=0
fail() {
    echo "error: $*" >&2
    failures=$((failures + 1))
}

# Relative target for a link, e.g. ".claude/skills" -> "../.agents/skills".
relative_target() {
    local depth
    depth="$(dirname "$1" | awk -F/ '{ n = ($0 == ".") ? 0 : NF; print n }')"
    local prefix=""
    for ((i = 0; i < depth; i++)); do prefix+="../"; done
    echo "${prefix}${SOURCE}"
}

if [[ ! -d "$SOURCE" ]]; then
    echo "error: $SOURCE does not exist" >&2
    exit 1
fi

for link in "${LINKS[@]}"; do
    target="$(relative_target "$link")"

    if [[ -L "$link" ]]; then
        current="$(readlink "$link")"
        if [[ "$current" == "$target" ]]; then
            continue
        fi
        fail "$link points to '$current', expected '$target'"
    elif [[ -e "$link" ]]; then
        fail "$link exists and is not a symlink; move it aside so it can link to $SOURCE"
    elif [[ "$mode" == "check" ]]; then
        fail "$link is missing; run 'make skills'"
    else
        mkdir -p "$(dirname "$link")"
        ln -s "$target" "$link"
        echo "linked $link -> $target"
    fi
done

# Every skill must be a folder holding a SKILL.md whose `name` matches the
# folder name (required by the Agent Skills spec; Codex enforces it).
for dir in "$SOURCE"/*/; do
    dir="${dir%/}"
    folder="$(basename "$dir")"
    file="$dir/SKILL.md"

    if [[ ! -f "$file" ]]; then
        fail "$dir has no SKILL.md"
        continue
    fi

    # `name:` from the first YAML frontmatter block only.
    name="$(awk '
        NR == 1 && $0 != "---" { exit }
        NR > 1 && $0 == "---" { exit }
        /^name:/ { sub(/^name:[ \t]*/, ""); gsub(/["'\'']|[ \t\r]+$/, ""); print; exit }
    ' "$file")"

    if [[ -z "$name" ]]; then
        fail "$file has no 'name' in its frontmatter"
    elif [[ "$name" != "$folder" ]]; then
        fail "$file has name '$name' but its folder is '$folder'"
    fi
done

if ((failures > 0)); then
    exit 1
fi

if [[ "$mode" == "check" ]]; then
    echo "agent skills OK"
fi
