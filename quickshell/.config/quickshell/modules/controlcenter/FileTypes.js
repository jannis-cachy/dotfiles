.pragma library

// File types shown on the Applications page. mimes: first one is read back as the current
// default, all get the chosen app. apps: desktop ids in preference order, only installed ones
// show (max 3). nvim-kitty and yazi-kitty come from the "apps" stow package.
const textMimes = ["text/plain", "text/markdown", "text/x-python", "text/x-tex", "text/x-lua", "text/x-csrc", "text/x-c++src", "text/csv", "text/x-qml", "application/x-shellscript", "application/json", "application/xml", "application/x-yaml", "application/toml"];
const imageMimes = ["image/png", "image/jpeg", "image/gif", "image/webp", "image/bmp", "image/tiff", "image/avif"];

const types = [
    {
        label: "Text and code",
        mimes: textMimes,
        apps: [
            { name: "Neovim", id: "nvim-kitty.desktop" },
            { name: "Text Editor", id: "org.gnome.TextEditor.desktop" },
            { name: "Micro", id: "micro.desktop" }
        ]
    },
    {
        label: "PDF",
        mimes: ["application/pdf"],
        apps: [
            { name: "Zathura", id: "org.pwmt.zathura-pdf-poppler.desktop" },
            { name: "Firefox", id: "firefox.desktop" },
            { name: "Okular", id: "org.kde.okular.desktop" }
        ]
    },
    {
        label: "Images",
        mimes: imageMimes,
        apps: [
            { name: "Swayimg", id: "swayimg.desktop" },
            { name: "qView", id: "com.interversehq.qView.desktop" },
            { name: "Firefox", id: "firefox.desktop" }
        ]
    },
    {
        label: "SVG",
        mimes: ["image/svg+xml"],
        apps: [
            { name: "Swayimg", id: "swayimg.desktop" },
            { name: "qView", id: "com.interversehq.qView.desktop" },
            { name: "Neovim", id: "nvim-kitty.desktop" }
        ]
    },
    {
        label: "Video",
        mimes: ["video/mp4", "video/x-matroska", "video/webm", "video/quicktime"],
        apps: [
            { name: "mpv", id: "mpv.desktop" },
            { name: "Firefox", id: "firefox.desktop" }
        ]
    },
    {
        label: "Audio",
        mimes: ["audio/mpeg", "audio/flac", "audio/ogg", "audio/x-wav", "audio/mp4"],
        apps: [
            { name: "mpv", id: "mpv.desktop" },
            { name: "Firefox", id: "firefox.desktop" }
        ]
    },
    {
        label: "Archives",
        mimes: ["application/zip", "application/x-tar", "application/x-7z-compressed", "application/vnd.rar", "application/x-rar", "application/gzip", "application/x-xz", "application/zstd"],
        apps: [
            { name: "Ark", id: "org.kde.ark.desktop" },
            { name: "File Roller", id: "org.gnome.FileRoller.desktop" }
        ]
    },
    {
        label: "Folders",
        mimes: ["inode/directory"],
        apps: [
            { name: "Dolphin", id: "org.kde.dolphin.desktop" },
            { name: "Thunar", id: "thunar.desktop" },
            { name: "Yazi", id: "yazi-kitty.desktop" }
        ]
    },
    {
        label: "Web pages",
        mimes: ["text/html", "x-scheme-handler/http", "x-scheme-handler/https"],
        apps: [
            { name: "Firefox", id: "firefox.desktop" }
        ]
    },
    {
        label: "Password databases",
        mimes: ["application/x-keepass2"],
        apps: [
            { name: "KeePassXC", id: "org.keepassxc.KeePassXC.desktop" }
        ]
    }
];
