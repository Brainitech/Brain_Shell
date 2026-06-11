pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "."

/*!
    AppSearch — native DesktopEntries app provider + fuzzy search.

    Replaces the Python list_apps.py script with Quickshell's built-in
    DesktopEntries singleton, providing instant app loading and fuzzy search.

    Usage:
        property var apps: AppSearch.getAllApps()
        property var results: AppSearch.fuzzyQuery("fire")
*/
QtObject {
    id: root

    // ── Icon cache ────────────────────────────────────────────────────────────
    property var iconCache: ({})

    function getCachedIcon(str) {
        if (!str) return "application-x-executable";
        if (iconCache[str]) return iconCache[str];
        const result = guessIcon(str);
        iconCache[str] = result;
        return result;
    }

    function guessIcon(str) {
        if (!str || str.length === 0) return "application-x-executable";
        // Try direct icon name
        if (Quickshell.iconPath(str, true).length > 0) return str;
        // Try with common suffixes
        const dashed = str.toLowerCase().replace(/\s+/g, "-");
        if (Quickshell.iconPath(dashed, true).length > 0) return dashed;
        // Fallback: use a generic executable icon instead of a missing one
        return "application-x-executable";
    }

    // ── DesktopEntries integration ────────────────────────────────────────────
    readonly property list<DesktopEntry> list: Array.from(DesktopEntries.applications.values)
        .sort((a, b) => a.name.localeCompare(b.name))

    property var allAppsCache: null
    property var searchIndex: []

    // Debounce index building — DesktopEntries populates incrementally,
    // so onListChanged fires once per app. A 200ms debounce batches them.
    property var _indexTimer: Timer {
        interval: 200
        repeat: false
        onTriggered: {
            console.log("[AppSearch] building index, count:", list.length)
            buildIndex()
        }
    }

    onListChanged: {
        allAppsCache = null;
        _indexTimer.restart();
    }

    Component.onCompleted: {
        console.log("[AppSearch] completed, DesktopEntries apps:", list.length)
        _indexTimer.restart()
    }

    function buildIndex() {
        const newIndex = [];
        for (let i = 0; i < list.length; i++) {
            const app = list[i];
            newIndex.push({
                name: app.name.toLowerCase(),
                command: (app.command && app.command.length > 0) ? app.command.join(' ').toLowerCase() : "",
                executable: (app.command && app.command.length > 0) ? app.command[0].toLowerCase() : "",
                comment: (app.comment || "").toLowerCase(),
                genericName: (app.genericName || "").toLowerCase(),
                keywords: (app.keywords || []).map(k => k.toLowerCase()),
                original: app
            });
        }
        searchIndex = newIndex;
    }

    function invalidateCache() {
        allAppsCache = null;
    }

    // ── Get all apps (sorted by usage) ────────────────────────────────────────
    function getAllApps() {
        if (allAppsCache) return allAppsCache;

        const results = [];
        for (let i = 0; i < list.length; i++) {
            const app = list[i];
            const usageScore = UsageTracker ? UsageTracker.getUsageScore(app.id) : 0;
            let iconToUse = app.icon || "application-x-executable";
            iconToUse = getCachedIcon(iconToUse);

            results.push({
                name: app.name,
                icon: iconToUse,
                id: app.id,
                execString: app.execString,
                comment: app.comment || "",
                categories: app.categories || [],
                runInTerminal: app.runInTerminal || false,
                usageScore: usageScore,
                execute: () => { launchApp(app); }
            });
        }
        results.sort((a, b) => {
            if (a.usageScore !== b.usageScore) return b.usageScore - a.usageScore;
            return a.name.localeCompare(b.name);
        });
        allAppsCache = results;
        return results;
    }

    // ── Fuzzy search ──────────────────────────────────────────────────────────
    function fuzzyQuery(search) {
        if (!search || search.length === 0) return [];
        const searchLower = search.toLowerCase();
        const results = [];

        if (searchIndex.length === 0 && list.length > 0) buildIndex();

        for (let i = 0; i < searchIndex.length; i++) {
            const entry = searchIndex[i];
            let score = 0;
            let matchFound = false;

            if (entry.name === searchLower) {
                score += 100; matchFound = true;
            } else if (entry.name.startsWith(searchLower)) {
                score += 80; matchFound = true;
            } else if (entry.name.includes(searchLower)) {
                score += 60; matchFound = true;
            }

            if (entry.command && entry.command.includes(searchLower)) {
                score += 40; matchFound = true;
            }
            if (entry.executable.includes(searchLower)) {
                score += 50; matchFound = true;
            }
            if (entry.comment && entry.comment.includes(searchLower)) {
                score += 30; matchFound = true;
            }
            if (entry.genericName && entry.genericName.includes(searchLower)) {
                score += 25; matchFound = true;
            }
            if (entry.keywords.length > 0) {
                for (let j = 0; j < entry.keywords.length; j++) {
                    if (entry.keywords[j].includes(searchLower)) {
                        score += 20; matchFound = true; break;
                    }
                }
            }

            if (matchFound) {
                const app = entry.original;
                const usageScore = UsageTracker ? UsageTracker.getUsageScore(app.id) : 0;
                let iconToUse = app.icon || "application-x-executable";
                iconToUse = getCachedIcon(iconToUse);
                results.push({
                    name: app.name,
                    icon: iconToUse,
                    score: score,
                    id: app.id,
                    execString: app.execString,
                    comment: app.comment || "",
                    categories: app.categories || [],
                    runInTerminal: app.runInTerminal || false,
                    usageScore: usageScore,
                    execute: () => { launchApp(app); }
                });
            }
        }

        results.sort((a, b) => {
            const totalA = a.score + a.usageScore;
            const totalB = b.score + b.usageScore;
            if (totalA !== totalB) return totalB - totalA;
            return (a.name || "").localeCompare(b.name || "");
        });

        return results.slice(0, 10);
    }

    // ── Launch app ────────────────────────────────────────────────────────────
    function launchApp(app) {
        const path = app.fileName || app.path || app.filePath;
        if (path && path.toString().endsWith('.desktop')) {
            const escapedPath = path.toString().replace(/'/g, "'\\''");
            runDetached("gio launch '" + escapedPath + "'");
            return;
        }
        if (app.command && app.command.length > 0) {
            const safeArgs = [];
            for (let i = 0; i < app.command.length; i++) {
                const arg = app.command[i];
                if (/^%[fFuUijkc]$/.test(arg)) continue;
                safeArgs.push("'" + arg.replace(/'/g, "'\\''") + "'");
            }
            if (safeArgs.length > 0) {
                const cmd = safeArgs.join(" ");
                const wrapped = app.runInTerminal ? "xdg-terminal-exec " + cmd : cmd;
                runDetached(wrapped);
                return;
            }
        }
        app.execute();
    }

    property Process _detachedProc: Process {
        command: []
        running: false
    }

    function runDetached(command) {
        _detachedProc.command = ["bash", "-c", "cd ~ && setsid " + command + " > /dev/null 2>&1 &"]
        _detachedProc.running = false
        _detachedProc.running = true
    }
}
