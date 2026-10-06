pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../theme"

// Pushes the quickshell font/icon/theme/cursor choice into GTK3, GTK4 and Qt (qt6ct) so native
// apps match, and live-applies the cursor via hyprctl. Patches only those keys in each live
// ~/.config file, everything else (style, color scheme) is left exactly as it is.
Singleton {
    id: root

    function setKey(file, section, key, value) {
        Quickshell.execDetached(["bash", "-c", `
f="$1"; s="$2"; k="$3"; v="$4"
mkdir -p "$(dirname "$f")"
touch "$f"
grep -q "^\\[$s\\]" "$f" || printf '\\n[%s]\\n' "$s" >> "$f"
if grep -q "^$k=" "$f"; then
    sed -i "s#^$k=.*#$k=$v#" "$f"
else
    sed -i "/^\\[$s\\]/a $k=$v" "$f"
fi
`, "bash", file, section, key, value]);
    }

    function apply() {
        const home = Quickshell.env("HOME");
        // GTK/Qt "general" font is the UI font; the nerd/mono font only goes to qt6ct's "fixed" slot
        const gtkFont = `${Theme.font.uiFamily} ${Theme.font.fontSize}`;
        // qt6ct's QFont serialization: family,pointSize,pixelSize,styleHint,weight,style,underline,strikeOut,fixedPitch,rawMode
        const qtFont = `"${Theme.font.uiFamily},${Theme.font.fontSize},-1,5,400,0,0,0,0,0"`;
        const qtFixedFont = `"${Theme.font.family},${Theme.font.fontSize},-1,5,400,0,0,0,0,0"`;

        for (const dir of ["gtk-3.0", "gtk-4.0"]) {
            const file = `${home}/.config/${dir}/settings.ini`;
            setKey(file, "Settings", "gtk-font-name", gtkFont);
            setKey(file, "Settings", "gtk-icon-theme-name", Theme.font.iconTheme);
            setKey(file, "Settings", "gtk-theme-name", Theme.font.gtkTheme);
            setKey(file, "Settings", "gtk-cursor-theme-name", Theme.font.cursorTheme);
            setKey(file, "Settings", "gtk-cursor-theme-size", String(Theme.font.cursorSize));
        }

        const qtFile = `${home}/.config/qt6ct/qt6ct.conf`;
        setKey(qtFile, "Appearance", "icon_theme", Theme.font.iconTheme);
        setKey(qtFile, "Fonts", "general", qtFont);
        setKey(qtFile, "Fonts", "fixed", qtFixedFont);

        // KDE apps (Dolphin, Ark) read the icon theme from kdeglobals before qt6ct
        setKey(`${home}/.config/kdeglobals`, "Icons", "Theme", Theme.font.iconTheme);

        // GTK on Wayland prefers these gsettings over settings.ini, and running GTK apps follow
        // them live (theme, icons, cursor, font), which settings.ini alone never does
        Quickshell.execDetached(["bash", "-c", `
g=org.gnome.desktop.interface
gsettings set $g gtk-theme "$1"
gsettings set $g icon-theme "$2"
gsettings set $g cursor-theme "$3"
gsettings set $g cursor-size "$4"
gsettings set $g font-name "$5"
`, "bash", Theme.font.gtkTheme, Theme.font.iconTheme, Theme.font.cursorTheme, String(Theme.font.cursorSize), gtkFont]);

        // qt6ct has no cursor key of its own, Qt/Wayland apps read XCURSOR_THEME/XCURSOR_SIZE.
        // hyprctl live-applies cursor changes to already-running clients, no restart needed -- except
        // Hyprland's cursor manager skips the reload when the theme name doesn't change, which is the
        // common case for a size-only tweak. Nudge it through an intermediate size first to force one.
        Quickshell.execDetached(["bash", "-c", `hyprctl setcursor "$1" 1 >/dev/null 2>&1; hyprctl setcursor "$1" "$2"`, "bash", Theme.font.cursorTheme, String(Theme.font.cursorSize)]);
    }

    Component.onCompleted: apply()

    Connections {
        target: Theme.font

        function onFamilyChanged() {
            root.apply();
        }
        function onUiFamilyChanged() {
            root.apply();
        }
        function onFontSizeChanged() {
            root.apply();
        }
        function onIconThemeChanged() {
            root.apply();
        }
        function onGtkThemeChanged() {
            root.apply();
        }
        function onCursorThemeChanged() {
            root.apply();
        }
        function onCursorSizeChanged() {
            root.apply();
        }
    }
}
