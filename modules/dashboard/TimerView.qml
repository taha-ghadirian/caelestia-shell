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

    property bool showDescriptionInput: false
    property string descriptionText: ""

    onShowDescriptionInputChanged: ProjectTimer.keyboardInputNeeded = showDescriptionInput

    spacing: Appearance.spacing.large * 2

    // Left panel
    Item {
        Layout.topMargin: root.pad
        Layout.bottomMargin: root.pad
        Layout.leftMargin: root.pad * 2
        Layout.alignment: Qt.AlignTop
        Layout.preferredWidth: root.panelWidth
        implicitWidth: root.panelWidth
        implicitHeight: leftColumn.implicitHeight

        ColumnLayout {
            id: leftColumn

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Appearance.spacing.large

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

                    StyledText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: ProjectTimer.formatMs(ProjectTimer.elapsedMs)
                        font.pointSize: Appearance.font.size.extraLarge * 1.8
                        font.family: Appearance.font.family.mono
                        font.weight: Font.Light
                        color: Colours.palette.m3onSurface
                    }

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

                enabled: !root.showDescriptionInput && (ProjectTimer.running || projectList.currentIndex >= 0)
                opacity: enabled ? 1 : 0.5

                onClicked: {
                    if (ProjectTimer.running) {
                        root.descriptionText = "";
                        root.showDescriptionInput = true;
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

                            StyledRect { implicitWidth: 10; implicitHeight: 10; radius: 5; color: projRow.projColor }

                            StyledText {
                                Layout.fillWidth: true
                                text: projRow.modelData.name ?? ""
                                font.pointSize: Appearance.font.size.smaller
                                color: projRow.selected ? projRow.projColor : Colours.palette.m3onSurface
                                Behavior on color { CAnim {} }
                            }

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
                                if (!ProjectTimer.running && !root.showDescriptionInput)
                                    projectList.currentIndex = projRow.index === projectList.currentIndex ? -1 : projRow.index;
                            }
                        }
                    }

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

        // Description overlay
        StyledRect {
            id: descriptionOverlay

            anchors.fill: parent
            radius: Appearance.rounding.large
            color: Colours.tPalette.m3surface
            visible: root.showDescriptionInput || descFadeAnim.running
            opacity: root.showDescriptionInput ? 1 : 0
            Behavior on opacity { Anim { id: descFadeAnim; duration: Appearance.anim.durations.large } }

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: root.pad
                spacing: Appearance.spacing.large

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "rate_review"
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.extraLarge
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("What did you work on?")
                    font.pointSize: Appearance.font.size.larger
                    font.weight: Font.Medium
                    color: Colours.palette.m3onSurface
                    wrapMode: Text.WordWrap
                }

                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: descField.implicitHeight + Appearance.padding.normal * 2
                    radius: Appearance.rounding.normal
                    color: Colours.tPalette.m3surfaceContainer
                    border.color: descField.activeFocus ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
                    border.width: descField.activeFocus ? 2 : 1
                    Behavior on border.color { CAnim {} }

                    StyledTextField {
                        id: descField

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.normal

                        placeholderText: qsTr("Short description (optional)")
                        text: root.descriptionText
                        onTextChanged: root.descriptionText = text
                        Keys.onReturnPressed: confirmBtn.clicked()
                        Keys.onEscapePressed: skipBtn.clicked()
                    }

                    Connections {
                        target: root
                        function onShowDescriptionInputChanged(): void {
                            if (root.showDescriptionInput) {
                                descField.text = "";
                                descField.forceActiveFocus();
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal

                    IconTextButton {
                        id: skipBtn
                        Layout.fillWidth: true
                        icon: "skip_next"
                        text: qsTr("Skip")
                        type: IconTextButton.Tonal
                        onClicked: {
                            root.showDescriptionInput = false;
                            ProjectTimer.stop("");
                        }
                    }

                    IconTextButton {
                        id: confirmBtn
                        Layout.fillWidth: true
                        icon: "check_circle"
                        text: qsTr("Save")
                        type: IconTextButton.Filled
                        onClicked: {
                            root.showDescriptionInput = false;
                            ProjectTimer.stop(root.descriptionText.trim());
                        }
                    }
                }
            }
        }
    }

    // Right panel: history
    ColumnLayout {
        Layout.topMargin: root.pad
        Layout.bottomMargin: root.pad
        Layout.rightMargin: root.pad * 2
        Layout.alignment: Qt.AlignTop
        Layout.preferredWidth: root.panelWidth
        spacing: Appearance.spacing.normal

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: qsTr("Session History")
                font.pointSize: Appearance.font.size.small
                font.weight: Font.Medium
                color: Colours.palette.m3onSurface
            }

            Item { Layout.fillWidth: true }

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
                text: qsTr("Clear all")
                type: IconTextButton.Tonal
                onClicked: ProjectTimer.clearRecords()
            }
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: root.panelHeight
            radius: Appearance.rounding.normal
            color: Colours.tPalette.m3surfaceContainer
            clip: true

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
                    readonly property string description: modelData.description ?? ""
                    property bool hovered: false

                    implicitWidth: recordList.width
                    implicitHeight: recContent.implicitHeight + Appearance.padding.smaller * 2
                    radius: Appearance.rounding.small
                    color: rec.hovered ? Qt.alpha(projColor, 0.14) : Qt.alpha(projColor, 0.08)
                    Behavior on color { CAnim {} }

                    HoverHandler {
                        onHoveredChanged: rec.hovered = hovered
                    }

                    RowLayout {
                        id: recContent

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Appearance.padding.smaller
                        spacing: Appearance.spacing.small

                        StyledRect {
                            implicitWidth: 3
                            implicitHeight: recTexts.implicitHeight
                            radius: 2
                            color: rec.projColor
                        }

                        ColumnLayout {
                            id: recTexts
                            Layout.fillWidth: true
                            spacing: 1

                            StyledText {
                                Layout.fillWidth: true
                                text: rec.modelData.project ?? ""
                                font.pointSize: Appearance.font.size.smaller
                                color: Colours.palette.m3onSurface
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: ProjectTimer.formatDate(rec.modelData.date ?? "")
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3outlineVariant
                            }

                            StyledText {
                                Layout.fillWidth: true
                                visible: rec.description !== ""
                                text: "\u201c" + rec.description + "\u201d"
                                font.pointSize: Appearance.font.size.small
                                font.italic: true
                                color: Colours.palette.m3onSurfaceVariant
                                elide: Text.ElideRight
                            }
                        }

                        ColumnLayout {
                            spacing: Appearance.spacing.smaller / 2
                            Layout.alignment: Qt.AlignTop

                            StyledRect {
                                implicitWidth: durLabel.implicitWidth + Appearance.padding.smaller * 2
                                implicitHeight: durLabel.implicitHeight + 4
                                radius: Appearance.rounding.full
                                color: Qt.alpha(rec.projColor, 0.2)

                                StyledText {
                                    id: durLabel
                                    anchors.centerIn: parent
                                    text: ProjectTimer.formatDuration(rec.modelData.duration ?? 0)
                                    font.pointSize: Appearance.font.size.small
                                    font.family: Appearance.font.family.mono
                                    color: rec.projColor
                                }
                            }

                            Item {
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: deleteIcon.implicitWidth
                                implicitHeight: rec.hovered ? deleteIcon.implicitHeight : 0
                                clip: true
                                opacity: rec.hovered ? 1 : 0
                                Behavior on implicitHeight { Anim {} }
                                Behavior on opacity { Anim {} }

                                MaterialIcon {
                                    id: deleteIcon
                                    anchors.centerIn: parent
                                    text: "delete"
                                    color: Colours.palette.m3error
                                    font.pointSize: Appearance.font.size.large

                                    StateLayer {
                                        color: Colours.palette.m3error
                                        onClicked: ProjectTimer.deleteRecord(rec.index)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
