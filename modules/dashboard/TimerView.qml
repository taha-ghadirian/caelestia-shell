pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.components.containers
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    readonly property int pad: Appearance.padding.large
    readonly property int panelWidth: 320
    readonly property int panelHeight: 380

    spacing: Appearance.spacing.large * 2

    // ── Left panel: active timer + project picker ───────────────────────────
    ColumnLayout {
        Layout.topMargin: root.pad
        Layout.bottomMargin: root.pad
        Layout.leftMargin: root.pad * 2
        Layout.alignment: Qt.AlignTop
        Layout.preferredWidth: root.panelWidth

        spacing: Appearance.spacing.large

        // Active timer card
        StyledRect {
            id: timerCard

            Layout.fillWidth: true
            implicitHeight: timerCardContent.implicitHeight + root.pad * 2
            radius: Appearance.rounding.large
            color: Colours.tPalette.m3surfaceContainer

            ColumnLayout {
                id: timerCardContent

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: root.pad

                spacing: Appearance.spacing.small

                // Running indicator dot
                RowLayout {
                    spacing: Appearance.spacing.small

                    StyledRect {
                        implicitWidth: 8
                        implicitHeight: 8
                        radius: 4
                        color: ProjectTimer.running ? Colours.palette.m3error : Colours.palette.m3outlineVariant

                        Behavior on color { CAnim {} }

                        SequentialAnimation on opacity {
                            running: ProjectTimer.running
                            loops: Animation.Infinite
                            Anim { to: 0.3; duration: 600; easing.type: Easing.InOutSine }
                            Anim { to: 1;   duration: 600; easing.type: Easing.InOutSine }
                        }
                        opacity: ProjectTimer.running ? 1 : 0.4
                    }

                    StyledText {
                        text: ProjectTimer.running ? qsTr("Running") : qsTr("Idle")
                        font.pointSize: Appearance.font.size.small
                        color: ProjectTimer.running ? Colours.palette.m3error : Colours.palette.m3outlineVariant
                        Behavior on color { CAnim {} }
                    }
                }

                // Elapsed time
                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: ProjectTimer.formatMs(ProjectTimer.elapsedMs)
                    font.pointSize: Appearance.font.size.extraLarge * 1.8
                    font.family: Appearance.font.family.mono
                    font.weight: Font.Light
                    color: Colours.palette.m3onSurface
                }

                // Project name
                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: ProjectTimer.running ? ProjectTimer.activeProject : qsTr("Select a project")
                    font.pointSize: Appearance.font.size.small
                    color: ProjectTimer.running
                        ? (ProjectTimer.activeColor || Colours.palette.m3primary)
                        : Colours.palette.m3outlineVariant

                    Behavior on color { CAnim {} }
                }
            }
        }

        // Start / Stop button
        IconTextButton {
            id: startStopBtn
            Layout.fillWidth: true

            icon: ProjectTimer.running ? "stop_circle" : "play_circle"
            text: ProjectTimer.running ? qsTr("Stop Timer") : qsTr("Start Timer")
            type: IconTextButton.Filled
            inactiveColour: ProjectTimer.running ? Colours.palette.m3error : Colours.palette.m3primary
            inactiveOnColour: ProjectTimer.running ? Colours.palette.m3onError : Colours.palette.m3onPrimary
            activeColour: inactiveColour
            activeOnColour: inactiveOnColour

            enabled: ProjectTimer.running || projectList.currentIndex >= 0
            opacity: enabled ? 1 : 0.5

            onClicked: {
                if (ProjectTimer.running) {
                    ProjectTimer.stop();
                } else {
                    const idx = projectList.currentIndex;
                    if (idx < 0)
                        return;
                    const proj = Config.timer.projects[idx];
                    if (!proj)
                        return;
                    ProjectTimer.start(proj.name ?? "", proj.color ?? proj["color scheme"] ?? "#808080");
                }
            }

            Behavior on opacity { Anim {} }
        }

        // ── Project list ──────────────────────────────────────────────────
        StyledText {
            text: qsTr("Projects")
            font.pointSize: Appearance.font.size.small
            color: Colours.palette.m3outlineVariant
            leftPadding: 4
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: Math.min(projectList.contentHeight + root.pad, root.panelHeight - timerCard.implicitHeight - startStopBtn.implicitHeight - 80)
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer
            clip: true

            StyledListView {
                id: projectList

                anchors.fill: parent
                anchors.margins: Appearance.padding.smaller
                spacing: Appearance.spacing.smaller / 2
                clip: true
                model: Config.timer.projects

                property int currentIndex: -1

                // Reset selection index when running state changes
                onModelChanged: currentIndex = -1

                delegate: StyledRect {
                    id: projRow

                    required property var modelData
                    required property int index

                    readonly property bool selected: projectList.currentIndex === index
                    readonly property string projColor: modelData.color ?? modelData["color scheme"] ?? Colours.palette.m3primary

                    implicitWidth: projectList.width
                    implicitHeight: projContent.implicitHeight + Appearance.padding.smaller * 2
                    radius: Appearance.rounding.small
                    color: selected ? Qt.alpha(projColor, 0.18) : "transparent"

                    Behavior on color { CAnim {} }

                    // Highlight border when selected
                    border.color: selected ? projColor : "transparent"
                    border.width: selected ? 1 : 0
                    Behavior on border.color { CAnim {} }

                    RowLayout {
                        id: projContent

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.smaller

                        spacing: Appearance.spacing.small

                        // Color dot
                        StyledRect {
                            implicitWidth: 10
                            implicitHeight: 10
                            radius: 5
                            color: projRow.projColor
                        }

                        // Project name
                        StyledText {
                            Layout.fillWidth: true
                            text: projRow.modelData.name ?? ""
                            font.pointSize: Appearance.font.size.smaller
                            color: projRow.selected ? projRow.projColor : Colours.palette.m3onSurface
                            Behavior on color { CAnim {} }
                        }

                        // Total logged time
                        StyledText {
                            text: ProjectTimer.formatMs(ProjectTimer.totalForProject(projRow.modelData.name ?? ""))
                            font.pointSize: Appearance.font.size.small
                            font.family: Appearance.font.family.mono
                            color: Colours.palette.m3outlineVariant
                        }
                    }

                    StateLayer {
                        color: Colours.palette.m3onSurface
                        onClicked: {
                            if (!ProjectTimer.running)
                                projectList.currentIndex = projRow.index === projectList.currentIndex ? -1 : projRow.index;
                        }
                    }
                }

                // Empty state
                Item {
                    anchors.centerIn: parent
                    width: parent.width
                    visible: projectList.count === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Appearance.spacing.small

                        MaterialIcon {
                            Layout.alignment: Qt.AlignHCenter
                            text: "folder_open"
                            color: Colours.palette.m3outlineVariant
                            font.pointSize: Appearance.font.size.extraLarge
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: qsTr("No projects configured")
                            color: Colours.palette.m3outlineVariant
                            font.pointSize: Appearance.font.size.small
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: qsTr("Add projects to shell.json")
                            color: Colours.palette.m3outlineVariant
                            font.pointSize: Appearance.font.size.small
                        }
                    }
                }
            }
        }
    }

    // ── Right panel: records history ────────────────────────────────────────
    ColumnLayout {
        Layout.topMargin: root.pad
        Layout.bottomMargin: root.pad
        Layout.rightMargin: root.pad * 2
        Layout.alignment: Qt.AlignTop
        Layout.preferredWidth: root.panelWidth

        spacing: Appearance.spacing.normal

        // Header + Clear button
        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: qsTr("Session History")
                font.pointSize: Appearance.font.size.small
                font.weight: Font.Medium
                color: Colours.palette.m3onSurface
            }

            Item { Layout.fillWidth: true }

            // Total time badge
            StyledRect {
                visible: ProjectTimer.records.length > 0
                implicitWidth: totalLabel.implicitWidth + Appearance.padding.smaller * 2
                implicitHeight: totalLabel.implicitHeight + 4
                radius: Appearance.rounding.full
                color: Qt.alpha(Colours.palette.m3primary, 0.15)

                StyledText {
                    id: totalLabel
                    anchors.centerIn: parent
                    text: ProjectTimer.formatMs(ProjectTimer.records.reduce((a, r) => a + r.duration, 0))
                    font.pointSize: Appearance.font.size.small
                    font.family: Appearance.font.family.mono
                    color: Colours.palette.m3primary
                }
            }

            IconTextButton {
                visible: ProjectTimer.records.length > 0
                icon: "delete_sweep"
                text: qsTr("Clear")
                type: IconTextButton.Tonal
                onClicked: ProjectTimer.clearRecords()
            }
        }

        // Records list
        StyledRect {
            Layout.fillWidth: true
            implicitHeight: root.panelHeight
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer
            clip: true

            // Empty state
            ColumnLayout {
                anchors.centerIn: parent
                visible: ProjectTimer.records.length === 0
                spacing: Appearance.spacing.small

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "history"
                    color: Colours.palette.m3outlineVariant
                    font.pointSize: Appearance.font.size.extraLarge
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("No sessions recorded yet")
                    color: Colours.palette.m3outlineVariant
                    font.pointSize: Appearance.font.size.small
                }
            }

            StyledListView {
                id: recordList

                anchors.fill: parent
                anchors.margins: Appearance.padding.smaller
                spacing: Appearance.spacing.smaller / 2
                clip: true
                model: ProjectTimer.records

                delegate: StyledRect {
                    id: rec

                    required property var modelData
                    required property int index

                    readonly property string projColor: modelData.color ?? "#808080"

                    implicitWidth: recordList.width
                    implicitHeight: recContent.implicitHeight + Appearance.padding.smaller * 2
                    radius: Appearance.rounding.small
                    color: Qt.alpha(projColor, 0.08)

                    RowLayout {
                        id: recContent

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.smaller

                        spacing: Appearance.spacing.small

                        // Color accent bar
                        StyledRect {
                            implicitWidth: 3
                            implicitHeight: recText.implicitHeight + dateText.implicitHeight + 2
                            radius: 2
                            color: rec.projColor
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            StyledText {
                                id: recText
                                Layout.fillWidth: true
                                text: modelData.project ?? ""
                                font.pointSize: Appearance.font.size.smaller
                                color: Colours.palette.m3onSurface
                                elide: Text.ElideRight
                            }

                            StyledText {
                                id: dateText
                                Layout.fillWidth: true
                                text: ProjectTimer.formatDate(modelData.date ?? "")
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3outlineVariant
                            }
                        }

                        // Duration badge
                        StyledRect {
                            implicitWidth: durLabel.implicitWidth + Appearance.padding.smaller * 2
                            implicitHeight: durLabel.implicitHeight + 4
                            radius: Appearance.rounding.full
                            color: Qt.alpha(rec.projColor, 0.2)

                            StyledText {
                                id: durLabel
                                anchors.centerIn: parent
                                text: ProjectTimer.formatDuration(modelData.duration ?? 0)
                                font.pointSize: Appearance.font.size.small
                                font.family: Appearance.font.family.mono
                                color: rec.projColor
                            }
                        }
                    }
                }
            }
        }
    }
}
