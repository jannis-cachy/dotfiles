.pragma library

// hjkl as arrow aliases. Returns "left", "down", "up", "right" or "" (other key or ctrl/alt/meta held)
function vim(event) {
    if (event.modifiers & 0x1c000000)
        return "";
    switch (event.key) {
    case 0x48:
        return "left";
    case 0x4a:
        return "down";
    case 0x4b:
        return "up";
    case 0x4c:
        return "right";
    }
    return "";
}
