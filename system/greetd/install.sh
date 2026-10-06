#!/bin/sh
# Run as: sudo ./install.sh   (needs: pacman -S cage)
# Installs the quickshell greeter. The old tuigreet config stays at /etc/greetd/config.toml.tuigreet
set -e
dir="$(cd "$(dirname "$0")" && pwd)"
owner="${SUDO_USER:-jannis}"

command -v cage >/dev/null || { echo "cage missing"; exit 1; }

# Shared wallpaper dir, writable by the owner (the quickshell picker copies into it), readable by greeter
mkdir -p /var/lib/greeter-wallpapers
chown "$owner": /var/lib/greeter-wallpapers
chmod 755 /var/lib/greeter-wallpapers
for f in "$dir"/../../Wallpapers/Wallpapers/*; do
    [ -f "$f" ] && install -o "$owner" -m 644 "$f" /var/lib/greeter-wallpapers/
done

[ -f /etc/greetd/config.toml.tuigreet ] || cp /etc/greetd/config.toml /etc/greetd/config.toml.tuigreet
rm -rf /etc/greetd/greeter
cp -r "$dir/greeter" /etc/greetd/greeter
install -m 755 "$dir/greeter-session.sh" /etc/greetd/greeter-session.sh
install -m 644 "$dir/config.toml" /etc/greetd/config.toml
echo "done, takes effect at the next login screen"
echo "restore: sudo cp /etc/greetd/config.toml.tuigreet /etc/greetd/config.toml"
