#!/usr/bin/env bash
# Post-install hook for GTK module

deploy_configs "$RICECTL_ROOT/configs/common/gtk-3.0" "$HOME/.config/gtk-3.0"
deploy_configs "$RICECTL_ROOT/configs/common/gtk-4.0" "$HOME/.config/gtk-4.0"
success "GTK dark theme configured"
