#!/usr/bin/env bash
# Setup script for custom Home Assistant development repositories
# This script creates symlinks from config/custom_components/ to repos in /workspaces/custom_dev/

set -e

CUSTOM_DEV_DIR="/workspaces/custom_dev"
HA_CONFIG_DIR="/workspaces/hacoredev/config"
CUSTOM_COMPONENTS_DIR="${HA_CONFIG_DIR}/custom_components"

echo "Setting up custom development environment..."

# Create directories if they don't exist
mkdir -p "${CUSTOM_DEV_DIR}"
mkdir -p "${CUSTOM_COMPONENTS_DIR}"

# Function to create symlink for an integration
create_integration_symlink() {
    local repo_path="$1"
    local repo_name
    repo_name=$(basename "${repo_path}")

    # Check if repo has custom_components directory
    if [[ -d "${repo_path}/custom_components" ]]; then
        # Iterate through each integration in the repo
        for integration_dir in "${repo_path}/custom_components"/*; do
            if [[ -d "${integration_dir}" ]]; then
                local integration_name
                integration_name=$(basename "${integration_dir}")
                local target_link="${CUSTOM_COMPONENTS_DIR}/${integration_name}"

                # Remove existing symlink or directory
                if [[ -L "${target_link}" ]]; then
                    echo "  Removing existing symlink: ${target_link}"
                    rm "${target_link}"
                elif [[ -d "${target_link}" ]]; then
                    echo "  Warning: ${target_link} is a directory, not a symlink. Skipping."
                    echo "  To use the symlink, remove the directory manually: rm -rf ${target_link}"
                    continue
                fi

                # Create symlink
                echo "  Creating symlink: ${integration_name} -> ${integration_dir}"
                ln -s "${integration_dir}" "${target_link}"
            fi
        done
    fi
}

# Function to setup git safe directory
setup_git_safe_dir() {
    local repo_path="$1"
    if [[ -d "${repo_path}/.git" ]]; then
        git config --global --add safe.directory "${repo_path}" 2>/dev/null || true
    fi
}

# Process all repositories in custom_dev directory
if [[ -d "${CUSTOM_DEV_DIR}" ]]; then
    echo "Scanning ${CUSTOM_DEV_DIR} for custom component repositories..."

    for repo_dir in "${CUSTOM_DEV_DIR}"/*; do
        if [[ -d "${repo_dir}" ]]; then
            repo_name=$(basename "${repo_dir}")
            echo "Processing: ${repo_name}"

            # Setup git safe directory
            setup_git_safe_dir "${repo_dir}"

            # Create integration symlinks
            create_integration_symlink "${repo_dir}"
        fi
    done
else
    echo "Custom dev directory not found: ${CUSTOM_DEV_DIR}"
    echo "Creating directory..."
    mkdir -p "${CUSTOM_DEV_DIR}"
fi

echo ""
echo "Custom development setup complete!"
echo ""
echo "To add a new custom integration:"
echo "  1. Clone your repo to ${CUSTOM_DEV_DIR}/"
echo "  2. Ensure it has structure: custom_components/<domain>/"
echo "  3. Run this script again or restart the container"
echo ""
