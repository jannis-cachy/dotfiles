.pragma library

// Apps left out of the launcher unless "More apps in launcher" is on. Desktop file id,
// lowercased, without .desktop. Steam games are detected by their Exec line, not listed here.
var ids = [
    "protontricks",
    "protontricks-launch",
    "winetricks",
    "org.gnome.calculator",
    "net.lutris.lutris",
    "com.heroicgameslauncher.hgl",
    "io.github.benjamimgois.goverlay",
    "gay.pancake.lsfg-vk-ui",
    "avahi-discover",
    "bssh",
    "bvnc",
    "qv4l2",
    "qvidcap",
    "lstopo",
    "xfce4-about",
    "uuctl",
    "cachyos-hello",
    "cachyos-pi",
    "org.cachyos.scx-manager",
    "org.cachyos.kernelmanager",
    "limine-snapper-restore",
    "rofi",
    "rofi-theme-selector",
    "thunar-settings",
    "thunar-bulk-rename",
    "blackmagicraw-player",
    "blackmagicraw-speedtest",
    "davincicontrolpanelssetup",
    "org.gnome.meld",
    "dev.lemmy.swash",
    "weylus",
    "io.github.eugeniosegala.mako",
    "io.github.eugeniosegala.mako.uninstaller",
    "xdvi",
    "vim",
    "micro",
    "alacritty"
];

function isSteamGame(entry) {
    return (entry.execString || "").indexOf("steam://rungameid") !== -1;
}

function isHidden(entry) {
    const id = (entry.id || "").toLowerCase().replace(/\.desktop$/, "");
    return ids.indexOf(id) !== -1 || isSteamGame(entry);
}
