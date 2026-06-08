#!/usr/bin/env bash
#
# install.sh — install this repository's agents, commands, and skills into a
# Claude Code (or compatible) configuration directory.
#
# Usage:
#   ./scripts/install.sh --tool claude-code
#   ./scripts/install.sh --tool claude-code --only agents
#   ./scripts/install.sh --tool claude-code --dry-run
#   ./scripts/install.sh --tool claude-code --force
#
# Then activate any agent in your Claude Code sessions, e.g.:
#   "Hey Claude, activate Frontend Developer mode and help me build a React component"

set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve repository root (parent of this script's directory).
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Source locations within the repo.
SRC_AGENTS="${REPO_ROOT}/.claude/agents"
SRC_COMMANDS="${REPO_ROOT}/.claude/commands"
SRC_SKILLS="${REPO_ROOT}/.agents/skills"

# ---------------------------------------------------------------------------
# Colors (disabled when not writing to a terminal).
# ---------------------------------------------------------------------------
if [ -t 1 ]; then
  BOLD="$(printf '\033[1m')"; DIM="$(printf '\033[2m')"
  GREEN="$(printf '\033[32m')"; YELLOW="$(printf '\033[33m')"
  RED="$(printf '\033[31m')"; BLUE="$(printf '\033[34m')"
  RESET="$(printf '\033[0m')"
else
  BOLD=""; DIM=""; GREEN=""; YELLOW=""; RED=""; BLUE=""; RESET=""
fi

info()  { printf '%s\n' "$*"; }
ok()    { printf '%s%s%s\n' "$GREEN" "$*" "$RESET"; }
warn()  { printf '%s%s%s\n' "$YELLOW" "$*" "$RESET" >&2; }
err()   { printf '%s%s%s\n' "$RED" "$*" "$RESET" >&2; }

# ---------------------------------------------------------------------------
# Defaults / argument parsing.
# ---------------------------------------------------------------------------
TOOL=""
ONLY=""          # empty = everything; otherwise: agents | commands | skills
DRY_RUN=0
FORCE=0
DEST_OVERRIDE=""

usage() {
  cat <<EOF
${BOLD}install.sh${RESET} — install agents, commands, and skills into your Claude Code directory.

${BOLD}Usage:${RESET}
  ./scripts/install.sh --tool <tool> [options]

${BOLD}Options:${RESET}
  --tool <tool>     Target tool. Supported: ${BOLD}claude-code${RESET} (default if omitted).
  --only <kind>     Install only one category: ${BOLD}agents${RESET}, ${BOLD}commands${RESET}, or ${BOLD}skills${RESET}.
  --dest <path>     Override the destination config directory (default: ~/.claude).
  --force           Overwrite existing files without prompting.
  --dry-run         Show what would be installed without writing anything.
  -h, --help        Show this help.

${BOLD}Examples:${RESET}
  ./scripts/install.sh --tool claude-code
  ./scripts/install.sh --tool claude-code --only agents
  ./scripts/install.sh --tool claude-code --dry-run
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --tool)    TOOL="${2:-}"; shift 2 ;;
    --tool=*)  TOOL="${1#*=}"; shift ;;
    --only)    ONLY="${2:-}"; shift 2 ;;
    --only=*)  ONLY="${1#*=}"; shift ;;
    --dest)    DEST_OVERRIDE="${2:-}"; shift 2 ;;
    --dest=*)  DEST_OVERRIDE="${1#*=}"; shift ;;
    --force)   FORCE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown argument: $1"; echo; usage; exit 2 ;;
  esac
done

# Default tool.
TOOL="${TOOL:-claude-code}"

case "$TOOL" in
  claude-code) ;;
  *) err "Unsupported --tool '$TOOL'. Supported: claude-code"; exit 2 ;;
esac

if [ -n "$ONLY" ]; then
  case "$ONLY" in
    agents|commands|skills) ;;
    *) err "Invalid --only '$ONLY'. Use: agents, commands, or skills."; exit 2 ;;
  esac
fi

# ---------------------------------------------------------------------------
# Destination layout for the selected tool.
# ---------------------------------------------------------------------------
DEST_ROOT="${DEST_OVERRIDE:-$HOME/.claude}"
DEST_AGENTS="${DEST_ROOT}/agents"
DEST_COMMANDS="${DEST_ROOT}/commands"
DEST_SKILLS="${DEST_ROOT}/skills"

# Counters.
COUNT_INSTALLED=0
COUNT_SKIPPED=0

# ---------------------------------------------------------------------------
# Helpers.
# ---------------------------------------------------------------------------

# run CMD...  — execute unless dry-run.
run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '%s$ %s%s\n' "$DIM" "$*" "$RESET"
  else
    "$@"
  fi
}

ensure_dir() {
  local dir="$1"
  if [ "$DRY_RUN" -eq 1 ]; then
    [ -d "$dir" ] || printf '%s$ mkdir -p %s%s\n' "$DIM" "$dir" "$RESET"
  else
    mkdir -p "$dir"
  fi
}

# install_file SRC DEST  — copy a single file, honoring --force / prompting.
install_file() {
  local src="$1" dest="$2"
  local name; name="$(basename "$src")"

  if [ -e "$dest" ] && [ "$FORCE" -ne 1 ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      warn "  skip (exists)   $name"
      COUNT_SKIPPED=$((COUNT_SKIPPED + 1))
      return
    fi
    printf '  %sexists%s %s — overwrite? [y/N] ' "$YELLOW" "$RESET" "$name"
    local reply; read -r reply </dev/tty || reply=""
    case "$reply" in
      y|Y|yes|YES) ;;
      *) warn "  skipped         $name"; COUNT_SKIPPED=$((COUNT_SKIPPED + 1)); return ;;
    esac
  fi

  run cp "$src" "$dest"
  ok "  installed       $name"
  COUNT_INSTALLED=$((COUNT_INSTALLED + 1))
}

# install_dir SRC_DIR DEST_DIR  — copy a skill directory (recursive).
install_dir() {
  local src="$1" dest="$2"
  local name; name="$(basename "$src")"

  if [ -e "$dest" ] && [ "$FORCE" -ne 1 ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      warn "  skip (exists)   $name/"
      COUNT_SKIPPED=$((COUNT_SKIPPED + 1))
      return
    fi
    printf '  %sexists%s %s/ — overwrite? [y/N] ' "$YELLOW" "$RESET" "$name"
    local reply; read -r reply </dev/tty || reply=""
    case "$reply" in
      y|Y|yes|YES) ;;
      *) warn "  skipped         $name/"; COUNT_SKIPPED=$((COUNT_SKIPPED + 1)); return ;;
    esac
  fi

  ensure_dir "$dest"
  run cp -R "$src/." "$dest/"
  ok "  installed       $name/"
  COUNT_INSTALLED=$((COUNT_INSTALLED + 1))
}

# ---------------------------------------------------------------------------
# Install routines.
# ---------------------------------------------------------------------------

install_agents() {
  if [ ! -d "$SRC_AGENTS" ]; then
    warn "No agents directory at ${SRC_AGENTS} — skipping."
    return
  fi
  shopt -s nullglob
  local files=("$SRC_AGENTS"/*.md)
  shopt -u nullglob
  if [ ${#files[@]} -eq 0 ]; then
    warn "No agents found in ${SRC_AGENTS} — skipping."
    return
  fi
  info "${BOLD}${BLUE}Agents${RESET} → ${DEST_AGENTS}"
  ensure_dir "$DEST_AGENTS"
  local f
  for f in "${files[@]}"; do
    install_file "$f" "${DEST_AGENTS}/$(basename "$f")"
  done
  echo
}

install_commands() {
  if [ ! -d "$SRC_COMMANDS" ]; then
    warn "No commands directory at ${SRC_COMMANDS} — skipping."
    return
  fi
  shopt -s nullglob
  local files=("$SRC_COMMANDS"/*.md)
  shopt -u nullglob
  if [ ${#files[@]} -eq 0 ]; then
    warn "No commands found in ${SRC_COMMANDS} — skipping."
    return
  fi
  info "${BOLD}${BLUE}Commands${RESET} → ${DEST_COMMANDS}"
  ensure_dir "$DEST_COMMANDS"
  local f
  for f in "${files[@]}"; do
    install_file "$f" "${DEST_COMMANDS}/$(basename "$f")"
  done
  echo
}

install_skills() {
  if [ ! -d "$SRC_SKILLS" ]; then
    warn "No skills directory at ${SRC_SKILLS} — skipping."
    return
  fi
  shopt -s nullglob
  local dirs=("$SRC_SKILLS"/*/)
  shopt -u nullglob
  if [ ${#dirs[@]} -eq 0 ]; then
    warn "No skills found in ${SRC_SKILLS} — skipping."
    return
  fi
  info "${BOLD}${BLUE}Skills${RESET} → ${DEST_SKILLS}"
  ensure_dir "$DEST_SKILLS"
  local d
  for d in "${dirs[@]}"; do
    d="${d%/}"
    install_dir "$d" "${DEST_SKILLS}/$(basename "$d")"
  done
  echo
}

# ---------------------------------------------------------------------------
# Main.
# ---------------------------------------------------------------------------
info "${BOLD}Installing into${RESET} ${DEST_ROOT} ${DIM}(tool: ${TOOL})${RESET}"
[ "$DRY_RUN" -eq 1 ] && warn "Dry run — no files will be written."
echo

case "$ONLY" in
  agents)   install_agents ;;
  commands) install_commands ;;
  skills)   install_skills ;;
  "")       install_agents; install_commands; install_skills ;;
esac

info "${BOLD}Done.${RESET} ${GREEN}${COUNT_INSTALLED} installed${RESET}, ${YELLOW}${COUNT_SKIPPED} skipped${RESET}."
if [ "$DRY_RUN" -eq 0 ] && [ "$COUNT_INSTALLED" -gt 0 ]; then
  echo
  info "Activate an agent in a Claude Code session, e.g.:"
  info "  ${DIM}\"Hey Claude, activate Frontend Developer mode and help me build a React component\"${RESET}"
fi
