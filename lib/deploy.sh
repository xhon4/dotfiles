#!/usr/bin/env bash
# ================================================================
#  ricectl config deployment
# ================================================================

source "$(dirname "${BASH_SOURCE[0]}")/core.sh" 2>/dev/null || true

# Deploy configs from source to destination using rsync (idempotent)
deploy_configs() {
    local src="$1"
    local dest="$2"

    if [[ ! -d "$src" ]]; then
        warn "Config source not found: $src"
        return 1
    fi

    mkdir -p "$dest"
    run "rsync -ah --backup --suffix=.bak '$src/' '$dest/'"
    success "Deployed: $src → $dest"
}

# Deploy a single file
deploy_file() {
    local src="$1"
    local dest="$2"

    if [[ ! -f "$src" ]]; then
        warn "File not found: $src"
        return 1
    fi

    local dest_dir
    dest_dir="$(dirname "$dest")"
    mkdir -p "$dest_dir"

    if [[ -f "$dest" ]] && diff -q "$src" "$dest" &>/dev/null; then
        success "Already up to date: $dest"
        return 0
    fi

    # Backup existing
    if [[ -f "$dest" ]]; then
        cp "$dest" "$dest.bak"
    fi

    run "cp '$src' '$dest'"
    success "Deployed: $(basename "$src") → $dest"
}

# Make all .sh files executable in a directory
fix_permissions() {
    local dir="$1"
    find "$dir" -name '*.sh' -exec chmod +x {} + 2>/dev/null
}

# Deploy module configs based on module.yaml
deploy_module() {
    local module_name="$1"
    local variant="${2:-}"
    local module_dir="$RICECTL_ROOT/modules/$module_name"
    local module_yaml="$module_dir/module.yaml"

    if [[ ! -f "$module_yaml" ]]; then
        error "Module not found: $module_name"
        return 1
    fi

    header "Module: $module_name"
    local prefix="mod"
    parse_yaml "$module_yaml" "$prefix"

    # Resolve config dir (module can override with config_dir field)
    local config_name="${mod_config_dir:-$module_name}"

    # Install packages
    install_module_packages "$module_yaml"

    # Deploy common configs
    local common_config="$RICECTL_ROOT/configs/common/$config_name"
    if [[ -d "$common_config" ]]; then
        deploy_configs "$common_config" "$HOME/.config/$config_name"
    fi

    # Deploy variant configs (override)
    if [[ -n "$variant" ]]; then
        local variant_config="$RICECTL_ROOT/configs/variants/$variant/$config_name"
        if [[ -d "$variant_config" ]]; then
            deploy_configs "$variant_config" "$HOME/.config/$config_name"
        fi
    fi

    # Enable services
    local services
    services=($(yaml_list "$prefix" "services"))
    if [[ ${#services[@]} -gt 0 ]]; then
        enable_services "${services[@]}"
    fi

    # Run post-install hook
    if [[ -f "$module_dir/post-install.sh" ]]; then
        info "Running post-install hook for $module_name..."
        source "$module_dir/post-install.sh"
    fi

    # Fix script permissions
    fix_permissions "$HOME/.config/$config_name" 2>/dev/null || true

    success "Module $module_name deployed"
}
