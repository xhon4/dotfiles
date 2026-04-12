#!/usr/bin/env bash
# ================================================================
#  ricectl TUI library — gum-powered interactive UI
#  Falls back to plain prompts if gum is not installed
# ================================================================

source "$(dirname "${BASH_SOURCE[0]}")/core.sh" 2>/dev/null || true

HAS_GUM=false
command -v gum &>/dev/null && HAS_GUM=true

# ================================================================
# HELPERS
# ================================================================

ensure_gum() {
    if [[ "$HAS_GUM" == "false" ]]; then
        warn "gum not installed. Install it for a better experience:"
        info "  sudo pacman -S gum"
        return 1
    fi
}

# ================================================================
# COMPONENTS
# ================================================================

# Styled header/banner
tui_header() {
    local text="$1"
    if $HAS_GUM; then
        gum style \
            --border double \
            --border-foreground 39 \
            --padding "1 3" \
            --margin "1 0" \
            --bold \
            "$text"
    else
        header "$text"
    fi
}

# Select one item from a list
# Usage: tui_choose "item1" "item2" "item3"
tui_choose() {
    if $HAS_GUM; then
        printf '%s\n' "$@" | gum choose --cursor.foreground 39 --header "Select one:"
    else
        local i=1
        local items=("$@")
        for item in "${items[@]}"; do
            echo "  [$i] $item"
            ((i++))
        done
        local choice
        read -rp "Select [1-${#items[@]}]: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#items[@]} )); then
            echo "${items[$((choice-1))]}"
        fi
    fi
}

# Select multiple items from a list
# Usage: tui_multichoose "item1" "item2" "item3"
tui_multichoose() {
    if $HAS_GUM; then
        printf '%s\n' "$@" | gum choose --no-limit --cursor.foreground 39 --header "Select modules (space to toggle, enter to confirm):"
    else
        # Fallback: select all
        printf '%s\n' "$@"
    fi
}

# Confirm yes/no
# Usage: tui_confirm "Do you want to continue?"
tui_confirm() {
    local msg="${1:-Continue?}"
    if $HAS_GUM; then
        gum confirm "$msg"
    else
        confirm "$msg"
    fi
}

# Spinner while running a command
# Usage: tui_spin "Installing packages..." -- sudo pacman -S --noconfirm pkg
tui_spin() {
    local title="$1"
    shift
    # Remove -- separator if present
    [[ "$1" == "--" ]] && shift

    if $HAS_GUM; then
        gum spin --spinner dot --title "$title" -- "$@"
    else
        info "$title"
        "$@"
    fi
}

# Text input
# Usage: tui_input "Enter your name" "default"
tui_input() {
    local prompt="$1"
    local default="${2:-}"
    if $HAS_GUM; then
        gum input --placeholder "$prompt" --value "$default" --cursor.foreground 39
    else
        local value
        read -rp "$prompt [$default]: " value
        echo "${value:-$default}"
    fi
}

# Display a filterable list (fuzzy finder)
# Usage: echo "items" | tui_filter "Search modules..."
tui_filter() {
    local placeholder="${1:-Filter...}"
    if $HAS_GUM; then
        gum filter --placeholder "$placeholder" --indicator "▸" --indicator.foreground 39
    else
        cat  # passthrough
    fi
}

# Show formatted log output
tui_log() {
    local level="$1"
    local msg="$2"
    if $HAS_GUM; then
        gum log --level "$level" "$msg"
    else
        case "$level" in
            info)  info "$msg" ;;
            warn)  warn "$msg" ;;
            error) error "$msg" ;;
            *)     echo "$msg" ;;
        esac
    fi
}

# Profile selector with descriptions
tui_select_profile() {
    local profiles_dir="$RICECTL_ROOT/profiles"
    local items=()
    local names=()

    for pfile in "$profiles_dir/"*.yaml; do
        local pname
        pname="$(basename "$pfile" .yaml)"
        local pdesc=""
        pdesc="$(grep '^description:' "$pfile" | head -1 | sed 's/description: *//')"
        items+=("$pname — $pdesc")
        names+=("$pname")
    done

    if $HAS_GUM; then
        local selected
        selected="$(printf '%s\n' "${items[@]}" | gum choose --cursor.foreground 39 --header "  Select a profile:")"
        # Extract name before " — "
        echo "${selected%% —*}"
    else
        local choice
        choice="$(tui_choose "${items[@]}")"
        echo "${choice%% —*}"
    fi
}

# Module selector (multi-select with descriptions)
tui_select_modules() {
    local items=()
    local names=()

    for module_dir in "$RICECTL_ROOT/modules"/*/; do
        local mod_name
        mod_name="$(basename "$module_dir")"
        local mod_yaml="$module_dir/module.yaml"
        [[ -f "$mod_yaml" ]] || continue

        local desc=""
        desc="$(grep '^description:' "$mod_yaml" | head -1 | sed 's/description: *//')"
        items+=("$mod_name — $desc")
        names+=("$mod_name")
    done

    if $HAS_GUM; then
        local selected
        selected="$(printf '%s\n' "${items[@]}" | gum choose --no-limit --cursor.foreground 39 --selected.foreground 42 --header "  Select modules (space to toggle):")"
        # Extract just names
        while IFS= read -r line; do
            echo "${line%% —*}"
        done <<< "$selected"
    else
        printf '%s\n' "${names[@]}"
    fi
}

# Variant selector
tui_select_variant() {
    if $HAS_GUM; then
        gum choose --cursor.foreground 39 --header "  Select variant:" "pc" "laptop"
    else
        tui_choose "pc" "laptop"
    fi
}

# Show a summary box before install
tui_install_summary() {
    local profile="$1"
    local variant="$2"
    local mod_count="$3"

    if $HAS_GUM; then
        gum style \
            --border rounded \
            --border-foreground 42 \
            --padding "1 2" \
            --margin "1 0" \
            "$(gum style --bold --foreground 42 "Install Summary")" \
            "" \
            "  Profile:  $(gum style --foreground 39 "$profile")" \
            "  Variant:  $(gum style --foreground 39 "$variant")" \
            "  Modules:  $(gum style --foreground 39 "$mod_count")" \
            "  Version:  $(gum style --foreground 39 "v$RICECTL_VERSION")"
    else
        echo ""
        info "Profile: $profile"
        info "Variant: $variant"
        info "Modules: $mod_count"
        info "Version: v$RICECTL_VERSION"
    fi
}
