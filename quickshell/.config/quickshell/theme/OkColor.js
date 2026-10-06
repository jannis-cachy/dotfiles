.pragma library

// Accepts "#rrggbb" or "oklch(L C H)" (L as 0..1 or percent, H in degrees, optional "/ alpha" ignored)
// and returns "#rrggbb". Out of gamut colors keep L and H and lose chroma until they fit sRGB.
const re = /^oklch\(\s*([\d.]+)(%?)[\s,]+([\d.]+)(%?)[\s,]+([\d.]+)(?:deg)?\s*(?:\/[^)]*)?\)$/i;

function parse(text) {
    const m = re.exec(text.trim());
    if (!m)
        return null;
    const L = parseFloat(m[1]) / (m[2] ? 100 : 1);
    const C = parseFloat(m[3]) * (m[4] ? 0.004 : 1);
    const H = parseFloat(m[5]);
    if (isNaN(L) || isNaN(C) || isNaN(H) || L > 1.0001)
        return null;
    return {
        L: L,
        C: C,
        H: H
    };
}

function linear(L, C, H) {
    const h = H * Math.PI / 180;
    const a = C * Math.cos(h);
    const b = C * Math.sin(h);
    const l = Math.pow(L + 0.3963377774 * a + 0.2158037573 * b, 3);
    const m = Math.pow(L - 0.1055613458 * a - 0.0638541728 * b, 3);
    const s = Math.pow(L - 0.0894841775 * a - 1.2914855480 * b, 3);
    return [4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s, -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s, -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s];
}

function inGamut(rgb) {
    return rgb.every(v => v >= -0.0005 && v <= 1.0005);
}

function toHex(text) {
    const t = text.trim();
    if (/^#[0-9a-f]{6}$/i.test(t))
        return t.toLowerCase();
    const p = parse(t);
    if (!p)
        return null;
    return okToHex(p.L, p.C, p.H);
}

function okToHex(L, C, H) {
    let rgb = linear(L, C, H);
    if (!inGamut(rgb)) {
        let lo = 0;
        let hi = C;
        for (let i = 0; i < 24; i++) {
            const mid = (lo + hi) / 2;
            if (inGamut(linear(L, mid, H)))
                lo = mid;
            else
                hi = mid;
        }
        rgb = linear(L, lo, H);
    }
    const enc = v => {
        v = Math.min(1, Math.max(0, v));
        v = v <= 0.0031308 ? 12.92 * v : 1.055 * Math.pow(v, 1 / 2.4) - 0.055;
        return Math.round(v * 255).toString(16).padStart(2, "0");
    };
    return "#" + enc(rgb[0]) + enc(rgb[1]) + enc(rgb[2]);
}

function hexToOk(hex) {
    const dec = i => {
        const v = parseInt(hex.substr(i, 2), 16) / 255;
        return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
    };
    const r = dec(1);
    const g = dec(3);
    const b = dec(5);
    const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
    const a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s;
    const bb = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s;
    return {
        L: 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
        C: Math.hypot(a, bb),
        H: Math.atan2(bb, a) * 180 / Math.PI
    };
}

// Global tweak of a picked color, all amounts -1..1 and 0 changes nothing:
// contrast spreads lightness around mid grey, brightness shifts it, saturation scales chroma
function adjust(hex, brightness, contrast, saturation) {
    if (!brightness && !contrast && !saturation)
        return hex;
    const o = hexToOk(hex);
    let L = 0.5 + (o.L - 0.5) * (1 + contrast * 0.6);
    L = Math.min(1, Math.max(0, L + brightness * 0.15));
    return okToHex(L, o.C * (1 + saturation), o.H);
}
