.pragma library

// Ranking for the file finder. entry = { name, rel, isDir, ext, depth } (all lowercase except display data)
const likelyExts = ["pdf", "tex", "md", "txt", "py", "lua", "qml", "sh", "odt", "docx", "xlsx", "pptx", "typ", "kdbx", "csv", "epub", "c", "cpp", "rs", "js"];
const unlikelyExts = ["json", "xml", "ini", "conf", "svg", "css", "html", "yml", "yaml", "toml", "sty", "cls", "bst"];

function isSubsequence(t, s) {
    let i = 0;
    for (let j = 0; j < s.length && i < t.length; j++) {
        if (s[j] === t[i])
            i++;
    }
    return i === t.length;
}

function wordStart(s, i) {
    return i === 0 || /[\s\-_.]/.test(s[i - 1]);
}

// Points for one query token, 0 means no match. Paths only count when the token has a slash.
function tokenScore(t, e) {
    if (t.includes("/"))
        return e.rel.includes(t) ? 60 : 0;
    const idx = e.name.indexOf(t);
    if (idx >= 0)
        return 100 + (idx === 0 ? 60 : wordStart(e.name, idx) ? 35 : 0);
    if (t.length >= 3 && isSubsequence(t, e.name)) {
        let run = 0, best = 0, k = 0;
        for (let j = 0; j < e.name.length && k < t.length; j++) {
            if (e.name[j] === t[k]) {
                run = (j > 0 && e.name[j - 1] === t[k - 1]) ? run + 1 : 1;
                best = Math.max(best, run);
                k++;
            } else {
                run = 0;
            }
        }
        return 20 + best * 4;
    }
    return 0;
}

// usage is the open count of this path, long names and deep paths only lose a little
function score(e, tokens, usage) {
    let total = 0;
    for (const t of tokens) {
        const s = tokenScore(t, e);
        if (s === 0)
            return 0;
        total += s;
    }
    total -= Math.min(e.name.length, 80) * 0.35;
    total -= Math.min(e.depth, 10) * 1.5;
    if (!e.isDir)
        total += 6;
    if (likelyExts.includes(e.ext))
        total += 8;
    else if (unlikelyExts.includes(e.ext))
        total -= 8;
    return total + Math.min(usage, 10) * 4;
}

// dirRel is the lowercase folder being browsed relative to home, "" for home itself. Without a
// query only its direct children show, with one everything below it is searched.
function search(entries, query, usageOf, limit, dirRel) {
    const tokens = query.toLowerCase().split(/\s+/).filter(t => t.length > 0);
    const prefix = dirRel === "" ? "" : dirRel + "/";
    const inDir = dirRel === "" ? entries : entries.filter(e => e.rel.startsWith(prefix));
    if (tokens.length === 0) {
        const depth = dirRel === "" ? 0 : dirRel.split("/").length;
        return inDir.filter(e => e.depth === depth).sort((a, b) => (usageOf(b.path) - usageOf(a.path)) || (b.isDir - a.isDir) || a.name.localeCompare(b.name)).slice(0, limit);
    }
    const hits = [];
    for (const e of inDir) {
        const s = score(e, tokens, usageOf(e.path));
        if (s > 0)
            hits.push({
                e: e,
                s: s
            });
    }
    hits.sort((a, b) => b.s - a.s || a.e.rel.length - b.e.rel.length);
    return hits.slice(0, limit).map(h => h.e);
}
