pragma Singleton
pragma ComponentBehavior: Bound

import qs.config
import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // ── Active timer state ──────────────────────────────────────────────────
    property string activeProject: ""
    property string activeColor: ""
    property bool running: false
    property bool keyboardInputNeeded: false
    property real elapsedMs: 0
    property date startTime

    // ── Saved records [{project, color, date, duration}] ───────────────────
    property list<var> records: []

    // ── Helpers ─────────────────────────────────────────────────────────────

    function formatMs(ms: real): string {
        const totalSecs = Math.floor(ms / 1000);
        const h = Math.floor(totalSecs / 3600);
        const m = Math.floor((totalSecs % 3600) / 60);
        const s = totalSecs % 60;
        return h.toString().padStart(2, "0") + ":"
             + m.toString().padStart(2, "0") + ":"
             + s.toString().padStart(2, "0");
    }

    function formatDuration(ms: real): string {
        return formatMs(ms);
    }

    function formatDate(isoStr: string): string {
        return new Date(isoStr).toLocaleString(Qt.locale(), "MMM d, yyyy  hh:mm");
    }

    // Total time (ms) logged for a given project name across all records
    function totalForProject(name: string): real {
        return records.reduce((acc, r) => acc + (r.project === name ? r.duration : 0), 0);
    }

    // ── Commands ─────────────────────────────────────────────────────────────

    function start(projectName: string, projectColor: string): void {
        if (running)
            stop();
        activeProject = projectName;
        activeColor = projectColor || "#808080";
        startTime = new Date();
        elapsedMs = 0;
        running = true;
    }

    function stop(description: string): void {
        if (!running)
            return;
        const now = new Date();
        const duration = now - startTime;
        const newRecord = {
            project: activeProject,
            color: activeColor,
            date: startTime.toISOString(),
            duration: duration,
            description: description ?? ""
        };
        // Prepend so newest is first
        records = [newRecord].concat(Array.from(records));
        running = false;
        activeProject = "";
        activeColor = "";
        elapsedMs = 0;
        saveRecords();
    }

    function deleteRecord(index: int): void {
        const arr = Array.from(records);
        arr.splice(index, 1);
        records = arr;
        saveRecords();
    }

    function clearRecords(): void {
        records = [];
        saveRecords();
    }

    function saveRecords(): void {
        mkdirProc.running = true;
    }

    // ── Internal helpers ─────────────────────────────────────────────────────

    readonly property string dataDir: Config.timer.savePath.replace(/^~/, Paths.home)
    readonly property string dataPath: dataDir + "/records.json"

    // Tick every second while running
    Timer {
        id: tickTimer
        interval: 1000
        repeat: true
        running: root.running
        onTriggered: root.elapsedMs = new Date() - root.startTime
    }

    // mkdir -p before writing so the directory always exists
    Process {
        id: mkdirProc
        command: ["mkdir", "-p", root.dataDir]
        onExited: (code, status) => {
            if (code === 0)
                dataFile.setText(JSON.stringify(root.records, null, 2));
        }
    }

    FileView {
        id: dataFile
        path: root.dataPath
        watchChanges: false
        onLoaded: {
            try {
                root.records = JSON.parse(text());
            } catch (e) {
                root.records = [];
            }
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                root.records = [];
                // Create the file on first run
                mkdirProc.running = true;
            }
        }
    }
}
