#!/usr/bin/env bash
# Post-install hook for zsh module

# Set zsh as default shell
if [[ "$SHELL" != "$(command -v zsh)" ]]; then
    info "Setting zsh as default shell"
    run "chsh -s $(command -v zsh)"
fi

# Install Zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
    info "Installing Zinit plugin manager"
    run "git clone https://github.com/zdharma-continuum/zinit.git '$ZINIT_HOME'"
fi

# Deploy zsh configs
deploy_file "$RICECTL_ROOT/.zshrc" "$HOME/.zshrc"
deploy_file "$RICECTL_ROOT/.p10k.zsh" "$HOME/.p10k.zsh"
