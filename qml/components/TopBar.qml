import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Rectangle {
    id: topBar

    property var theme: null
    property var i18n: null
    property var windowRef: null
    property string projectName: ""
    property string currentFileName: ""
    property bool fileModified: false
    property var templates: []
    property var settings: ({})
    property string newProjectTargetDir: ""
    readonly property bool settingsDialogOpen: settingsDialog.opened
    readonly property bool newProjectDialogOpen: newProjectDialog.opened
    property bool previewActive: true

    signal saveClicked()
    signal compileClicked()
    signal previewToggled()
    signal openProject(string path)
    signal createProject(string templateId, string targetDir, string projectName)
    signal themeToggleRequested()
    signal cleanAuxClicked()
    signal closeProjectRequested()
    signal settingsSaved(var settings)
    signal settingsSaveRequested(var settings)
    signal themeSelected(string themeName)

    property color themePanel: theme ? theme.panel : "#0D1728"
    property color themePanelSoft: theme ? theme.panelSoft : "#0C1627"
    property color themeBorder: theme ? theme.border : "#17263D"
    property color themeText: theme ? theme.text : "#F3F7FF"
    property color themeSubText: theme ? theme.subText : "#8EA3C2"
    property color themeAccent: theme ? theme.accent : "#5BA8FF"
    property color themeSuccess: theme ? theme.success : "#3DD598"
    property color themeWarning: theme ? theme.warning : "#FFBE5C"
    property color themeHover: theme ? theme.hover : "#182842"
    property int themeCardRadius: theme ? theme.cardRadius : 18
    property int themeButtonRadius: theme ? theme.buttonRadius : 12
    property int themeSmallFontSize: theme ? theme.smallFontSize : 11
    property int themeNormalFontSize: theme ? theme.normalFontSize : 13

    implicitHeight: 46
    radius: 0
    color: themePanel

    function toggleMaximized() {
        if (!windowRef) {
            return
        }
        if (windowRef.visibility === Window.Maximized) {
            windowRef.showNormal()
        } else {
            windowRef.showMaximized()
        }
    }

    function startWindowMove() {
        if (!windowRef) {
            return false
        }
        if (windowRef.startSystemMove) {
            return windowRef.startSystemMove()
        }
        return false
    }

    function trText(key) {
        return i18n ? i18n.t(key) : key
    }

    function templateText(templateId, fallbackName) {
        return i18n ? i18n.templateName(templateId, fallbackName) : fallbackName
    }

    function displayProjectName() {
        return projectName && projectName.length > 0 ? projectName : trText("topbar.noProject")
    }

    function displayFileName() {
        return currentFileName && currentFileName.length > 0 ? currentFileName : trText("topbar.noFile")
    }

    function openNewProjectDialog() {
        newProjectDialog.open()
    }

    function openProjectDialog() {
        folderDialog.open()
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: themeBorder
    }

    component CommandButton: Button {
        id: toolbarButton
        property bool accent: false
        property bool active: false
        property bool compact: false
        implicitHeight: 28
        implicitWidth: compact ? 32 : (accent ? 88 : 68)
        hoverEnabled: true
        leftPadding: compact ? 0 : 12
        rightPadding: compact ? 0 : 12
        topPadding: 6
        bottomPadding: 6

        background: Rectangle {
            radius: 7
            border.width: toolbarButton.accent || toolbarButton.active || toolbarButton.hovered || toolbarButton.down ? 1 : 0
            border.color: toolbarButton.accent ? themeAccent : themeBorder
            color: toolbarButton.down
                ? (toolbarButton.accent ? themeAccent : themeHover)
                : (toolbarButton.active ? themeHover
                : (toolbarButton.hovered ? (toolbarButton.accent ? themeAccent : themeHover)
                                         : (toolbarButton.accent ? themeAccent : "transparent")))
        }

        contentItem: Text {
            text: toolbarButton.text
            color: toolbarButton.accent ? (theme && !theme.darkMode ? "#FFFFFF" : "#08111F") : themeText
            font.pixelSize: toolbarButton.compact ? 15 : 12
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    component MenuLikeButton: Button {
        id: menuButton
        property bool active: false
        implicitHeight: 28
        leftPadding: 10
        rightPadding: 10
        topPadding: 6
        bottomPadding: 6
        hoverEnabled: true

        background: Rectangle {
            radius: 7
            color: menuButton.down || menuButton.hovered || menuButton.active ? themeHover : "transparent"
            border.width: menuButton.active ? 1 : 0
            border.color: themeBorder
        }

        contentItem: Text {
            text: menuButton.text
            color: themeText
            font.pixelSize: 12
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    component TitleDragArea: Item {
        id: dragArea
        property real previousMouseX: 0
        property real previousMouseY: 0
        property bool nativeMoveStarted: false
        Layout.fillWidth: true
        Layout.minimumWidth: 20
        Layout.preferredHeight: topBar.height

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.ArrowCursor
            preventStealing: true

            onPressed: function(mouse) {
                dragArea.previousMouseX = mouse.x
                dragArea.previousMouseY = mouse.y
                dragArea.nativeMoveStarted = topBar.startWindowMove()
                if (dragArea.nativeMoveStarted) {
                    mouse.accepted = true
                }
            }

            onPositionChanged: function(mouse) {
                if (!pressed || !topBar.windowRef || dragArea.nativeMoveStarted) {
                    return
                }
                topBar.windowRef.x += mouse.x - dragArea.previousMouseX
                topBar.windowRef.y += mouse.y - dragArea.previousMouseY
            }

            onDoubleClicked: topBar.toggleMaximized()
        }
    }

    component WindowControlButton: Button {
        id: windowButton
        property bool closeButton: false
        implicitWidth: 44
        implicitHeight: topBar.height
        hoverEnabled: true
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0

        background: Rectangle {
            color: windowButton.closeButton && windowButton.hovered
                ? "#D83B3B"
                : (windowButton.down || windowButton.hovered ? themeHover : "transparent")
        }

        contentItem: Text {
            text: windowButton.text
            color: windowButton.closeButton && windowButton.hovered ? "#FFFFFF" : themeText
            font.pixelSize: 14
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 0
        spacing: 8

        Rectangle {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            radius: 7
            color: themeAccent

            Text {
                anchors.centerIn: parent
                text: "LT"
                color: theme && !theme.darkMode ? "#FFFFFF" : "#08111F"
                font.pixelSize: 12
                font.weight: Font.Black
            }
        }

        CommandButton {
            text: "\u2630"
            compact: true
            onClicked: appMenu.open()

            Menu {
                id: appMenu
                y: parent.height + 4

                MenuItem {
                    text: trText("topbar.newProject")
                    onTriggered: newProjectDialog.open()
                }
                MenuItem {
                    text: trText("topbar.openProject")
                    onTriggered: folderDialog.open()
                }
                MenuSeparator {}
                MenuItem {
                    text: trText("topbar.save")
                    onTriggered: saveClicked()
                }
            }
        }

        MenuLikeButton {
            Layout.preferredWidth: 142
            text: displayProjectName() + "  \u25be"
            active: true
        }

        TitleDragArea {
            Layout.maximumWidth: 180
        }

        Rectangle {
            Layout.preferredWidth: 250
            Layout.maximumWidth: 300
            Layout.minimumWidth: 180
            Layout.preferredHeight: 28
            radius: 7
            color: themePanelSoft
            border.width: 1
            border.color: themeBorder

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: trText("topbar.currentFile") + " \u25be"
                    color: themeSubText
                    font.pixelSize: themeSmallFontSize
                }

                Text {
                    Layout.fillWidth: true
                    text: displayFileName()
                    color: themeText
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Rectangle {
                    visible: fileModified
                    Layout.preferredWidth: 58
                    Layout.preferredHeight: 20
                    radius: 6
                    color: theme && theme.darkMode ? "#2F2413" : "#FFF5DF"

                    Text {
                        anchors.centerIn: parent
                        text: trText("editor.modified")
                        color: themeWarning
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        TitleDragArea {
            Layout.minimumWidth: 36
        }

        CommandButton {
            text: trText("topbar.compile")
            accent: true
            onClicked: compileClicked()
        }

        CommandButton {
            text: trText("topbar.preview")
            active: topBar.previewActive
            onClicked: previewToggled()
        }

        CommandButton {
            text: trText("topbar.clean")
            onClicked: cleanAuxClicked()
        }

        CommandButton {
            text: theme && theme.darkMode ? trText("topbar.light") : trText("topbar.dark")
            onClicked: themeToggleRequested()
        }

        CommandButton {
            text: trText("topbar.settings")
            onClicked: settingsDialog.openWithSettings(settings)
        }

        CommandButton {
            text: "\u22ef"
            compact: true
            onClicked: moreMenu.open()

            Menu {
                id: moreMenu
                y: parent.height + 4

                MenuItem {
                    text: trText("topbar.closeProject")
                    onTriggered: closeProjectRequested()
                }
            }
        }

        WindowControlButton {
            text: "\u2212"
            onClicked: {
                if (topBar.windowRef) {
                    topBar.windowRef.showMinimized()
                }
            }
        }

        WindowControlButton {
            text: topBar.windowRef && topBar.windowRef.visibility === Window.Maximized ? "\u2750" : "\u25a1"
            onClicked: topBar.toggleMaximized()
        }

        WindowControlButton {
            text: "X"
            closeButton: true
            onClicked: {
                if (topBar.windowRef) {
                    topBar.windowRef.close()
                }
            }
        }
    }

    FolderDialog {
        id: folderDialog
        title: trText("topbar.openProject")
        onAccepted: openProject(selectedFolder.toString())
    }

    FolderDialog {
        id: projectLocationDialog
        title: trText("newProject.location")
        onAccepted: newProjectTargetDir = selectedFolder.toString()
    }

    Dialog {
        id: newProjectDialog
        parent: Overlay.overlay
        title: trText("newProject.title")
        modal: true
        width: 430
        height: 360
        anchors.centerIn: parent
        closePolicy: Popup.CloseOnEscape
        standardButtons: Dialog.NoButton

        background: Rectangle {
            radius: themeCardRadius
            color: themePanel
            border.width: 1
            border.color: themeBorder
        }

        contentItem: ColumnLayout {
            spacing: 14

            Text {
                text: trText("newProject.heading")
                color: themeText
                font.pixelSize: theme ? theme.titleFontSize : 18
                font.weight: Font.Bold
            }

            TextField {
                id: projectNameField
                Layout.fillWidth: true
                placeholderText: trText("newProject.projectName")
                text: "new_paper"
                color: themeText
                placeholderTextColor: themeSubText
                background: Rectangle {
                    radius: themeButtonRadius
                    color: themePanelSoft
                    border.width: 1
                    border.color: themeBorder
                }
            }

            ComboBox {
                id: templateBox
                Layout.fillWidth: true
                model: templates
                textRole: "name"
                valueRole: "id"
                background: Rectangle {
                    radius: themeButtonRadius
                    color: themePanelSoft
                    border.width: 1
                    border.color: themeBorder
                }
                contentItem: Text {
                    leftPadding: 12
                    text: templateText(templateBox.currentValue, templateBox.displayText)
                    color: themeText
                    font.pixelSize: themeNormalFontSize
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                TextField {
                    Layout.fillWidth: true
                    readOnly: true
                    text: newProjectTargetDir.length > 0 ? newProjectTargetDir : trText("newProject.location")
                    color: newProjectTargetDir.length > 0 ? themeText : themeSubText
                    background: Rectangle {
                        radius: themeButtonRadius
                        color: themePanelSoft
                        border.width: 1
                        border.color: themeBorder
                    }
                }

                Button {
                    text: trText("newProject.browse")
                    onClicked: projectLocationDialog.open()
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item { Layout.fillWidth: true }

                Button {
                    text: trText("newProject.cancel")
                    onClicked: newProjectDialog.close()
                }

                Button {
                    text: trText("newProject.create")
                    enabled: projectNameField.text.trim().length > 0
                        && newProjectTargetDir.length > 0
                        && templateBox.currentIndex >= 0
                    onClicked: {
                        createProject(templateBox.currentValue, newProjectTargetDir, projectNameField.text.trim())
                        newProjectDialog.close()
                    }
                }
            }
        }
    }

    SettingsDialog {
        id: settingsDialog
        parent: Overlay.overlay
        theme: topBar.theme
        i18n: topBar.i18n
        onSettingsSaved: function(nextSettings) {
            topBar.settingsSaved(nextSettings)
        }
        onThemeSelected: function(themeName) {
            themeSelected(themeName)
        }
    }
}
