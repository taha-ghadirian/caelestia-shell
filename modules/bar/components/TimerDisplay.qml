pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import QtQuick

Column {
    id: root

    property color colour: ProjectTimer.running
        ? Colours.palette.m3error
        : Colours.palette.m3outlineVariant

    // Only visible when a timer is active and the feature is enabled
    visible: Config.timer.enabled && ProjectTimer.running
    spacing: Appearance.spacing.small

    Behavior on colour { CAnim {} }

    // Timer icon (pulsing when running)
    MaterialIcon {
        id: timerIcon

        anchors.horizontalCenter: parent.horizontalCenter
        text: "timer"
        color: root.colour
        fill: ProjectTimer.running ? 1 : 0

        SequentialAnimation on opacity {
            running: ProjectTimer.running
            loops: Animation.Infinite
            alwaysRunToEnd: true
            Anim { to: 0.5; duration: 800; easing.type: Easing.InOutSine }
            Anim { to: 1;   duration: 800; easing.type: Easing.InOutSine }
        }
    }

    // Elapsed time (HH:MM:SS split to two lines MM:SS / HH)
    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        horizontalAlignment: StyledText.AlignHCenter
        text: ProjectTimer.formatMs(ProjectTimer.elapsedMs)
        font.pointSize: Appearance.font.size.small
        font.family: Appearance.font.family.mono
        color: root.colour
    }

    // Project name (truncated)
    StyledText {
        anchors.horizontalCenter: parent.horizontalCenter
        horizontalAlignment: StyledText.AlignHCenter
        text: ProjectTimer.activeProject
        font.pointSize: Appearance.font.size.small
        color: {
            const c = ProjectTimer.activeColor;
            return c && c !== "" ? c : root.colour;
        }
        width: Config.bar.sizes.innerWidth
        elide: Text.ElideRight
    }
}
