.pragma library

// Extra search terms per app. Key is the desktop file id (lowercased, without .desktop),
// searched next to the name, the id itself, the executable and the desktop file keywords.
var aliases = {
    "nm-connection-editor": ["nm", "network", "wifi", "ethernet", "vpn"],
    "org.pulseaudio.pavucontrol": ["audio", "sound", "volume", "mixer"],
    "org.kde.dolphin": ["files", "explorer"],
    "thunar": ["files", "explorer"],
    "com.obsproject.studio": ["obs", "record", "stream"],
    "btop": ["monitor", "task", "taskmanager", "top"],
    "qt6ct": ["theme", "qt"],
    "nwg-look": ["theme", "gtk"],
    "org.keepassxc.keepassxc": ["password", "passwords"]
};
