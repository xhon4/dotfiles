#!/usr/bin/env bash
# ================================================================
#  oxh-dotfiles — Bootstrap Installer
#
#  Prepares a clean Arch+Hyprland system to run ricectl:
#    1. Sanity checks (Arch, not root, sudo, internet)
#    2. Pacman update + base prerequisites
#    3. AUR helper bootstrap (yay or paru) if missing
#    4. Clone/update the dotfiles repo
#    5. Hand off to `ricectl install` for packages, fonts, configs, services
#    6. Print a final summary
#
#  Usage:
#    ./install.sh [--dry-run] [--help] [ricectl args...]
#
#  Re-running this script is safe: every step is gated by a presence check.
# ================================================================

set -euo pipefail

# ---------------------------------------------------------------
# Globals
# ---------------------------------------------------------------

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
REPO_URL="${REPO_URL:-https://github.com/xhon4/dotfiles.git}"
LOG_FILE="${LOG_FILE:-/tmp/oxh-install-$(date +%Y%m%d-%H%M%S).log}"

DRY_RUN=false
RICECTL_ARGS=()

STEP_NAMES=()
STEP_STATUS=()   # ok | skip | fail
STEP_DETAIL=()
CURRENT_STEP=""
HANDED_OFF=false
SUMMARY_PRINTED=false

if [[ -t 1 ]]; then
    C_RESET=$'\e[0m'; C_BLUE=$'\e[34m'; C_GREEN=$'\e[32m'
    C_YELLOW=$'\e[33m'; C_RED=$'\e[31m'; C_BOLD=$'\e[1m'
    C_CYAN=$'\e[36m'; C_DIM=$'\e[2m'
else
    C_RESET=''; C_BLUE=''; C_GREEN=''; C_YELLOW=''
    C_RED=''; C_BOLD=''; C_CYAN=''; C_DIM=''
fi

# ---------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------

log()     { printf '%s\n' "$*" >>"$LOG_FILE"; }
info()    { printf '%s[>]%s %s\n' "$C_BLUE"   "$C_RESET" "$1"; log "[INFO] $1"; }
success() { printf '%s[✓]%s %s\n' "$C_GREEN"  "$C_RESET" "$1"; log "[OK]   $1"; }
warn()    { printf '%s[!]%s %s\n' "$C_YELLOW" "$C_RESET" "$1"; log "[WARN] $1"; }
err()     { printf '%s[✗]%s %s\n' "$C_RED"    "$C_RESET" "$1" >&2; log "[ERR]  $1"; }

step_begin() {
    CURRENT_STEP="$1"
    printf '\n%s── %s%s\n' "$C_BOLD$C_CYAN" "$1" "$C_RESET"
    log "=== STEP: $1 ==="
}
step_record() {
    STEP_NAMES+=("$CURRENT_STEP")
    STEP_STATUS+=("$1")
    STEP_DETAIL+=("${2:-}")
    CURRENT_STEP=""
}
step_ok()   { step_record ok   "${1:-}"; }
step_skip() { step_record skip "${1:-}"; }
step_fail() { step_record fail "${1:-}"; }

# Run a state-changing command, honouring DRY_RUN.
run() {
    if $DRY_RUN; then
        printf '%s[dry-run]%s %s\n' "$C_DIM" "$C_RESET" "$*"
        log "[DRY] $*"
        return 0
    fi
    log "[CMD] $*"
    "$@"
}

# ---------------------------------------------------------------
# Traps
# ---------------------------------------------------------------

on_error() {
    local exit_code=$? line_no=$1
    err "Failed at line $line_no (exit $exit_code)"
    [[ -n "$CURRENT_STEP" ]] && step_fail "exit $exit_code @ line $line_no"
    print_summary
    SUMMARY_PRINTED=true
    err "Log: $LOG_FILE"
    exit "$exit_code"
}
on_exit() {
    # After successful exec into ricectl this never fires (the process
    # is replaced). On early/clean exits, print the summary unless
    # on_error already did.
    if ! $HANDED_OFF && ! $SUMMARY_PRINTED; then
        print_summary
    fi
}
trap 'on_error $LINENO' ERR
trap on_exit EXIT

# ---------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------

usage() {
    cat <<EOF
oxh-dotfiles bootstrap installer.

Usage:
  $(basename "$0") [--dry-run] [--help] [ricectl args...]

Options:
  --dry-run   Print actions without changing the system. Forwarded to ricectl.
  --help, -h  Show this help.

Any unrecognised argument is forwarded verbatim to 'ricectl install'.
Common ricectl flags: --profile=NAME, --variant=pc|laptop.

Environment:
  DOTFILES_DIR  Target directory for the repo (default: ~/.dotfiles)
  REPO_URL      Git URL of the dotfiles repo
  LOG_FILE      Install log (default: /tmp/oxh-install-<timestamp>.log)
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run) DRY_RUN=true; RICECTL_ARGS+=("$1") ;;
            --help|-h) usage; exit 0 ;;
            *)         RICECTL_ARGS+=("$1") ;;
        esac
        shift
    done
}

# ---------------------------------------------------------------
# Banner
# ---------------------------------------------------------------

banner() {
    printf '%s' "$C_BOLD$C_CYAN"
    cat <<'BANNER'

   ██████╗ ██╗  ██╗██╗  ██╗
  ██╔═══██╗╚██╗██╔╝██║  ██║
  ██║   ██║ ╚███╔╝ ███████║
  ██║   ██║ ██╔██╗ ██╔══██║
  ╚██████╔╝██╔╝ ██╗██║  ██║
   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
   oxh-dotfiles bootstrap

BANNER
    printf '%s' "$C_RESET"
    $DRY_RUN && printf '%s[dry-run mode — no changes will be made]%s\n' \
        "$C_YELLOW" "$C_RESET"
    printf '\n'
}

# ---------------------------------------------------------------
# Step 1 — Sanity checks
# ---------------------------------------------------------------

step_sanity() {
    step_begin "Sanity checks"
    local issues=0

    if [[ $EUID -eq 0 ]]; then
        err "Do not run as root. Use a normal user with sudo access."
        issues=$((issues + 1))
    else
        success "Running as non-root user ($(whoami))"
    fi

    if [[ ! -f /etc/os-release ]]; then
        err "Cannot detect OS (/etc/os-release missing)"
        issues=$((issues + 1))
    else
        # shellcheck disable=SC1091
        source /etc/os-release
        if [[ "${ID:-}" != "arch" ]]; then
            err "Requires Arch Linux (detected: ${ID:-unknown})"
            issues=$((issues + 1))
        else
            success "Arch Linux detected (${PRETTY_NAME:-arch})"
        fi
    fi

    if ! command -v sudo >/dev/null 2>&1; then
        err "sudo is not installed"
        issues=$((issues + 1))
    elif ! $DRY_RUN && ! sudo -v; then
        err "sudo authentication failed"
        issues=$((issues + 1))
    else
        success "sudo available"
    fi

    if ! ping -c 1 -W 3 archlinux.org >/dev/null 2>&1; then
        err "No internet connection (cannot reach archlinux.org)"
        issues=$((issues + 1))
    else
        success "Internet OK"
    fi

    if (( issues > 0 )); then
        step_fail "$issues issue(s)"
        err "Sanity checks failed — aborting"
        exit 1
    fi
    step_ok "all green"
}

# ---------------------------------------------------------------
# Step 2 — Pacman update + base prerequisites
# ---------------------------------------------------------------

step_pacman_base() {
    step_begin "Pacman update + base prerequisites"
    local prereqs=(git base-devel rsync curl)

    info "Refreshing system (sudo pacman -Syu)"
    run sudo pacman -Syu --needed --noconfirm

    info "Ensuring base prerequisites: ${prereqs[*]}"
    run sudo pacman -S --needed --noconfirm "${prereqs[@]}"

    success "Base prerequisites ready"
    step_ok "ensured: ${prereqs[*]}"
}

# ---------------------------------------------------------------
# Step 3 — AUR helper bootstrap
# ---------------------------------------------------------------

step_aur_helper() {
    step_begin "AUR helper"

    if command -v yay >/dev/null 2>&1; then
        success "yay already installed"
        step_skip "yay present"
        return
    fi
    if command -v paru >/dev/null 2>&1; then
        success "paru already installed"
        step_skip "paru present"
        return
    fi

    info "Bootstrapping yay from AUR"
    # Subshell so its EXIT trap cleans up the tmpdir even if any step
    # inside (clone or makepkg) fails under set -e.
    (
        local tmpdir
        tmpdir="$(mktemp -d -t oxh-yay-XXXXXX)"
        trap 'rm -rf "$tmpdir"' EXIT
        run git clone --depth=1 https://aur.archlinux.org/yay.git "$tmpdir/yay"
        if $DRY_RUN; then
            printf '%s[dry-run]%s cd %s/yay && makepkg -si --noconfirm\n' \
                "$C_DIM" "$C_RESET" "$tmpdir"
        else
            cd "$tmpdir/yay" && makepkg -si --noconfirm
        fi
    )
    success "yay installed"
    step_ok "yay bootstrapped"
}

# ---------------------------------------------------------------
# Step 4 — Repo clone or update
# ---------------------------------------------------------------

step_repo() {
    step_begin "Dotfiles repo"

    if [[ -d "$DOTFILES_DIR/.git" ]]; then
        info "Repo already at $DOTFILES_DIR — pulling latest"
        if run git -C "$DOTFILES_DIR" pull --rebase --autostash; then
            success "Repo updated"
            step_ok "pulled: $DOTFILES_DIR"
        else
            warn "git pull failed — using existing checkout"
            step_skip "pull failed, kept existing"
        fi
        return
    fi

    if [[ -e "$DOTFILES_DIR" ]]; then
        err "$DOTFILES_DIR exists but is not a git repo"
        step_fail "non-git path in the way"
        exit 1
    fi

    info "Cloning $REPO_URL → $DOTFILES_DIR"
    run git clone "$REPO_URL" "$DOTFILES_DIR"
    success "Repo cloned"
    step_ok "cloned: $DOTFILES_DIR"
}

# ---------------------------------------------------------------
# Step 5 — Hand off to ricectl (packages, fonts, configs, services)
# ---------------------------------------------------------------

step_handoff() {
    step_begin "Hand off to ricectl"

    local ricectl="$DOTFILES_DIR/ricectl"
    if [[ ! -f "$ricectl" ]]; then
        err "ricectl not found at $ricectl"
        step_fail "ricectl missing"
        exit 1
    fi
    # chmod is idempotent and read-only-safe; run it directly so dry-run
    # does not leave a non-executable file on the exec path.
    [[ -x "$ricectl" ]] || chmod +x "$ricectl"

    info "Forwarding to: $ricectl install ${RICECTL_ARGS[*]:-}"
    step_ok "starting ricectl"

    print_summary
    SUMMARY_PRINTED=true
    printf '\n%s── ricectl ──%s\n\n' "$C_BOLD$C_CYAN" "$C_RESET"

    HANDED_OFF=true
    # exec replaces this process; ricectl owns the rest of the install
    # (official + AUR packages, fonts, tools, configs, services).
    exec "$ricectl" install "${RICECTL_ARGS[@]}"
}

# ---------------------------------------------------------------
# Final summary
# ---------------------------------------------------------------

print_summary() {
    local n=${#STEP_NAMES[@]}
    (( n == 0 )) && return

    printf '\n%s── Summary ──%s\n' "$C_BOLD$C_CYAN" "$C_RESET"
    local i icon color name status detail
    local ok_count=0 skip_count=0 fail_count=0
    for (( i=0; i<n; i++ )); do
        name="${STEP_NAMES[$i]}"
        status="${STEP_STATUS[$i]}"
        detail="${STEP_DETAIL[$i]}"
        case "$status" in
            ok)   icon='✓'; color="$C_GREEN";  ok_count=$((ok_count+1)) ;;
            skip) icon='~'; color="$C_YELLOW"; skip_count=$((skip_count+1)) ;;
            fail) icon='✗'; color="$C_RED";    fail_count=$((fail_count+1)) ;;
            *)    icon='?'; color="$C_RESET" ;;
        esac
        printf '  %s%s%s %s' "$color" "$icon" "$C_RESET" "$name"
        [[ -n "$detail" ]] && printf ' %s(%s)%s' "$C_DIM" "$detail" "$C_RESET"
        printf '\n'
    done
    printf '\n  %d ok, %d skipped, %d failed\n' \
        "$ok_count" "$skip_count" "$fail_count"
    printf '  Log: %s\n' "$LOG_FILE"
}

# ---------------------------------------------------------------
# Main
# ---------------------------------------------------------------

main() {
    parse_args "$@"
    : >"$LOG_FILE"
    log "oxh-dotfiles installer started at $(date -Iseconds)"
    log "args: $*"
    banner

    step_sanity
    step_pacman_base
    step_aur_helper
    step_repo
    step_handoff   # exec — does not return on success
}

main "$@"
