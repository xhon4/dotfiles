#!/usr/bin/env bash
# Post-install hook for Docker module

# Add user to docker group
if ! groups "$USER" | grep -q docker; then
    info "Adding $USER to docker group"
    srun "usermod -aG docker $USER"
    warn "Log out and back in for docker group to take effect"
fi
