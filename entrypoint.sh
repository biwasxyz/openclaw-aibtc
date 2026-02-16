#!/bin/sh
set -e

# Persist wallet data (~/.aibtc) and moltbook credentials (~/.config/moltbook)
# across Docker rebuilds by symlinking them into the mounted volume at ~/.openclaw/
#
# The docker-compose volume mount (./data:/home/node/.openclaw) ensures everything
# under ~/.openclaw/ survives rebuilds. This script creates symlinks so that tools
# writing to ~/.aibtc or ~/.config/moltbook transparently use the volume.

# Ensure persistent directories exist inside the volume
mkdir -p /home/node/.openclaw/aibtc-data
mkdir -p /home/node/.openclaw/moltbook-data

# --- Wallet store (~/.aibtc → volume) ---
if [ -L /home/node/.aibtc ]; then
    : # Already a symlink, nothing to do
elif [ -d /home/node/.aibtc ]; then
    # Migrate existing data into the volume, then replace with symlink
    if cp -a /home/node/.aibtc/. /home/node/.openclaw/aibtc-data/ 2>/dev/null; then
        rm -rf /home/node/.aibtc
        ln -s /home/node/.openclaw/aibtc-data /home/node/.aibtc
    else
        echo "Warning: Failed to migrate ~/.aibtc data, skipping symlink" >&2
    fi
else
    ln -s /home/node/.openclaw/aibtc-data /home/node/.aibtc
fi

# --- Moltbook credentials (~/.config/moltbook → volume) ---
mkdir -p /home/node/.config
if [ -L /home/node/.config/moltbook ]; then
    : # Already a symlink
elif [ -d /home/node/.config/moltbook ]; then
    if cp -a /home/node/.config/moltbook/. /home/node/.openclaw/moltbook-data/ 2>/dev/null; then
        rm -rf /home/node/.config/moltbook
        ln -s /home/node/.openclaw/moltbook-data /home/node/.config/moltbook
    else
        echo "Warning: Failed to migrate ~/.config/moltbook data, skipping symlink" >&2
    fi
else
    ln -s /home/node/.openclaw/moltbook-data /home/node/.config/moltbook
fi

# Hand off to the original CMD
exec "$@"
