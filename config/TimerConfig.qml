import Quickshell.Io

JsonObject {
    // Set to false to hide the timer tab and bar widget entirely.
    property bool enabled: true

    // Path where timer records are saved. Use ~ for home directory.
    property string savePath: "~/.timer"

    // Define your projects here, e.g.:
    // { "name": "My Project", "color": "#6750A4" }
    property list<var> projects: []
}
