import Quickshell.Io

JsonObject {
    // Path where timer records are saved. Use ~ for home directory.
    property string savePath: "~/.timer"

    // Define your projects here, e.g.:
    // { "name": "My Project", "color": "#6750A4" }
    property list<var> projects: []
}
