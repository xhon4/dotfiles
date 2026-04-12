#!/usr/bin/env bash
# Post-install hook for SDDM module

SDDM_THEME_DIR="/usr/share/sddm/themes/oxh-sddm"

if [[ -d "$RICECTL_ROOT/system/sddm-theme" ]]; then
    srun "mkdir -p $SDDM_THEME_DIR"
    srun "cp -r $RICECTL_ROOT/system/sddm-theme/* $SDDM_THEME_DIR/"

    if [[ ! -f /etc/sddm.conf.d/theme.conf ]]; then
        srun "mkdir -p /etc/sddm.conf.d"
        echo -e '[Theme]\nCurrent=oxh-sddm' | sudo tee /etc/sddm.conf.d/theme.conf > /dev/null
    fi
    success "SDDM OXH theme deployed"
fi
