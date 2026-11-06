#!/usr/bin/env bash
# Installs every skill from this repo into a project, or globally.
# Usage:
#   ./scripts/install.sh /path/to/project   # project install
#   ./scripts/install.sh --global           # global install for all agents
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SKILLS_DIR="$REPO_DIR/skills"

# Copies one skill folder into a target skills directory.
copy_skill() {
  local skill_path="$1"
  local target_dir="$2"
  local skill_name
  skill_name="$(basename "$skill_path")"
  mkdir -p "$target_dir"
  rm -rf "${target_dir:?}/$skill_name"
  cp -R "$skill_path" "$target_dir/$skill_name"
  echo "  -> $target_dir/$skill_name"
}

# Adds a one-line pointer to AGENTS.md so agents without skill support still follow the skill.
add_agents_md_pointer() {
  local project_dir="$1"
  local skill_name="$2"
  local agents_file="$project_dir/AGENTS.md"
  local pointer="- For building apps or coding challenges, follow \`.agents/skills/$skill_name/SKILL.md\`."
  touch "$agents_file"
  if ! grep -qF "$pointer" "$agents_file"; then
    printf '\n%s\n' "$pointer" >> "$agents_file"
    echo "  -> pointer added to $agents_file"
  fi
}

if [ "${1:-}" = "--global" ]; then
  GLOBAL_DIRS=(
    "$HOME/.claude/skills"
    "$HOME/.codex/skills"
    "$HOME/.cursor/skills"
    "$HOME/.copilot/skills"
    "$HOME/.gemini/skills"
  )
  for skill in "$SKILLS_DIR"/*/; do
    echo "Installing $(basename "$skill") globally"
    for dir in "${GLOBAL_DIRS[@]}"; do
      copy_skill "${skill%/}" "$dir"
    done
  done
  exit 0
fi

PROJECT_DIR="${1:?Give a project path or --global}"
for skill in "$SKILLS_DIR"/*/; do
  name="$(basename "$skill")"
  echo "Installing $name into $PROJECT_DIR"
  copy_skill "${skill%/}" "$PROJECT_DIR/.agents/skills"
  copy_skill "${skill%/}" "$PROJECT_DIR/.claude/skills"
  add_agents_md_pointer "$PROJECT_DIR" "$name"
done
echo "Done."
