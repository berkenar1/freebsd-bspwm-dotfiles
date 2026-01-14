#!/bin/sh
#
# ZSH Plugins Installation Script for FreeBSD
# This script clones the required ZSH plugins for the dotfiles configuration
#

set -e

PLUGIN_DIR="$HOME/.zsh-plugins"

echo "Installing ZSH plugins to $PLUGIN_DIR..."

mkdir -p "$PLUGIN_DIR"

# Function to clone or update a plugin
install_plugin() {
    repo="$1"
    name="$2"
    
    if [ -d "$PLUGIN_DIR/$name" ]; then
        echo "Updating: $name"
        cd "$PLUGIN_DIR/$name"
        git pull --quiet --ff-only || echo "  Warning: Could not update $name (may have local changes)"
    else
        echo "Installing: $name"
        git clone --depth=1 "$repo" "$PLUGIN_DIR/$name"
    fi
}

# Core plugins
install_plugin "https://github.com/zsh-users/zsh-autosuggestions" "zsh-autosuggestions"
install_plugin "https://github.com/zsh-users/zsh-syntax-highlighting" "zsh-syntax-highlighting"
install_plugin "https://github.com/zsh-users/zsh-history-substring-search" "zsh-history-substring-search"
install_plugin "https://github.com/zsh-users/zsh-completions" "zsh-completions"

# Enhanced syntax highlighting
install_plugin "https://github.com/zdharma-continuum/fast-syntax-highlighting" "fast-syntax-highlighting"

# Git prompt
install_plugin "https://github.com/woefe/git-prompt.zsh" "git-prompt.zsh"

# Vi mode
install_plugin "https://github.com/jeffreytse/zsh-vi-mode" "vi-mode.zsh"

# fzf bindings
if [ ! -d "$PLUGIN_DIR/fzf" ]; then
    echo "Setting up fzf shell integration..."
    mkdir -p "$PLUGIN_DIR/fzf"
    
    # Try to find fzf installation and copy shell scripts
    for fzf_path in /usr/local/share/examples/fzf/shell /usr/local/share/fzf; do
        if [ -d "$fzf_path" ]; then
            cp -r "$fzf_path"/* "$PLUGIN_DIR/fzf/" 2>/dev/null || true
            break
        fi
    done
    
    # If not found, download from fzf repo
    if [ ! -f "$PLUGIN_DIR/fzf/completion.zsh" ]; then
        echo "Downloading fzf shell scripts..."
        curl -sL "https://raw.githubusercontent.com/junegunn/fzf/master/shell/completion.zsh" > "$PLUGIN_DIR/fzf/completion.zsh"
        curl -sL "https://raw.githubusercontent.com/junegunn/fzf/master/shell/key-bindings.zsh" > "$PLUGIN_DIR/fzf/key-bindings.zsh"
    fi
fi

echo ""
echo "ZSH plugins installed successfully!"
echo ""
echo "Restart your shell or run: source ~/.zshrc"
