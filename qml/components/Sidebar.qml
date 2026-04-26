import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: sidebar

    property var theme: null
    property var i18n: null
    property var openFiles: []
    property var projectTree: []
    property string projectName: ""
    property string currentFile: ""
    property string currentFilePath: ""
    property var collapsedDirs: ({})
    property var visibleProjectItems: []

    signal openFileRequested(string relativePath)
    signal unsupportedFileRequested(string relativePath)
    signal fileSelected(string relativePath)

    property color themePanel: theme ? theme.panel : "#0D1728"
    property color themePanelSoft: theme ? theme.panelSoft : "#0C1627"
    property color themeCard: theme ? theme.card : "#13233D"
    property color themeBorder: theme ? theme.border : "#17263D"
    property color themeText: theme ? theme.text : "#F3F7FF"
    property color themeSubText: theme ? theme.subText : "#8EA3C2"
    property color themeAccent: theme ? theme.accent : "#5BA8FF"
    property color themeWarning: theme ? theme.warning : "#FFBE5C"
    property color themeHover: theme ? theme.hover : "#182842"
    property int themeCardRadius: theme ? theme.cardRadius : 18
    property int themeSmallFontSize: theme ? theme.smallFontSize : 11
    property int themeNormalFontSize: theme ? theme.normalFontSize : 13

    radius: themeCardRadius
    color: themePanel
    border.width: 1
    border.color: themeBorder

    function fileNameFromPath(relativePath) {
        var parts = relativePath.split("/")
        return parts.length > 0 ? parts[parts.length - 1] : relativePath
    }

    function isExpanded(relativePath) {
        return collapsedDirs[relativePath] !== true
    }

    function toggleDirectory(relativePath) {
        var next = {}
        for (var key in collapsedDirs) {
            next[key] = collapsedDirs[key]
        }
        next[relativePath] = !next[relativePath]
        collapsedDirs = next
        refreshProjectItems()
    }

    function requestOpenFile(relativePath) {
        if (!relativePath || relativePath.length === 0) {
            return
        }
        openFileRequested(relativePath)
        fileSelected(relativePath)
    }

    function normalizedProjectNodes() {
        return projectTree
    }

    function projectRootName() {
        return projectName && projectName.length > 0 ? projectName : ""
    }

    function noProjectText() {
        return i18n && i18n.currentLanguage === "zh" ? "未打开项目" : "No project opened"
    }

    function noProjectHint() {
        return i18n && i18n.currentLanguage === "zh"
            ? "点击顶部的 新建 或 打开 开始写作"
            : "Use New Project or Open to get started."
    }

    function buildVisibleProjectItems() {
        var result = []
        var rootName = projectRootName()
        if (rootName.length === 0) {
            return result
        }

        result.push({
            "name": rootName,
            "relativePath": "",
            "loadable": false,
            "isDir": true,
            "isRoot": true,
            "depth": 0
        })

        if (isExpanded("")) {
            appendProjectNodes(normalizedProjectNodes(), 1, result)
        }
        return result
    }

    function refreshProjectItems() {
        visibleProjectItems = buildVisibleProjectItems()
    }

    function activeFilePath() {
        return currentFile.length > 0 ? currentFile : currentFilePath
    }

    function appendProjectNodes(nodes, depth, result) {
        for (var i = 0; i < nodes.length; i += 1) {
            var node = nodes[i]
            var nodePath = node.path || node.relativePath || ""
            var isDirectory = node.type === "directory" || node.isDir === true
            var extension = node.extension || ""
            var markerType = isDirectory ? "directory" : (extension.length > 0 ? extension : (node.type || ""))

            result.push({
                "name": node.name || fileNameFromPath(nodePath),
                "relativePath": nodePath,
                "type": markerType,
                "loadable": isDirectory ? false : node.loadable !== false,
                "openable": isDirectory ? false : node.openable === true,
                "isDir": isDirectory,
                "isRoot": false,
                "depth": depth
            })

            if (isDirectory && isExpanded(nodePath)) {
                var children = node.children || []
                appendProjectNodes(children, depth + 1, result)
            }
        }
    }

    Component.onCompleted: refreshProjectItems()
    onProjectNameChanged: refreshProjectItems()
    onProjectTreeChanged: refreshProjectItems()
    onCollapsedDirsChanged: refreshProjectItems()

    component SectionHeader: Text {
        Layout.fillWidth: true
        color: themeSubText
        font.pixelSize: themeSmallFontSize
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }

    component ProjectRow: Rectangle {
        required property string label
        required property string relativePath
        property bool active: false
        property bool loadable: false
        property bool openable: false
        property bool directory: false
        property bool rootNode: false
        property int depth: 0
        readonly property string displayText: label && label.length > 0 ? label : relativePath
        readonly property string tooltipText: relativePath && relativePath.length > 0 ? relativePath : displayText

        width: parent ? parent.width : 0
        height: visible ? 28 : 0
        radius: 7
        color: active ? themeHover : (projectMouse.containsMouse ? themePanelSoft : "transparent")
        border.width: active ? 1 : 0
        border.color: active ? themeBorder : "transparent"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8 + depth * 14
            anchors.rightMargin: 8
            spacing: 7

            Text {
                Layout.preferredWidth: 12
                text: directory ? (isExpanded(relativePath) ? "\u25be" : "\u25b8") : ""
                color: themeSubText
                font.pixelSize: 10
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 24
                text: displayText
                color: active ? themeText : themeSubText
                font.pixelSize: themeNormalFontSize
                font.weight: rootNode || active ? Font.DemiBold : Font.Medium
                elide: Text.ElideRight
                clip: true
            }
        }

        MouseArea {
            id: projectMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: directory || loadable || !rootNode ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (directory) {
                    sidebar.toggleDirectory(relativePath)
                } else if (loadable) {
                    sidebar.requestOpenFile(relativePath)
                } else if (relativePath.length > 0) {
                    sidebar.unsupportedFileRequested(relativePath)
                }
            }
        }

        ToolTip.delay: 450
        ToolTip.visible: projectMouse.containsMouse && tooltipText.length > 0
        ToolTip.text: tooltipText
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        SectionHeader {
            text: i18n ? i18n.t("sidebar.project") : "PROJECT"
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 8
            color: themePanelSoft
            border.width: 1
            border.color: themeBorder

            ScrollView {
                id: projectScroll
                anchors.fill: parent
                anchors.margins: 6
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                contentWidth: availableWidth
                contentHeight: projectTreeColumn.implicitHeight

                Column {
                    id: projectTreeColumn

                    width: projectScroll.availableWidth
                    spacing: 2

                    Repeater {
                        model: sidebar.visibleProjectItems

                        ProjectRow {
                            required property var modelData

                            label: modelData.name
                            relativePath: modelData.relativePath
                            loadable: modelData.loadable
                            openable: modelData.openable
                            directory: modelData.isDir
                            rootNode: modelData.isRoot
                            depth: modelData.depth
                            active: modelData.relativePath === sidebar.activeFilePath()
                        }
                    }

                    Text {
                        visible: sidebar.projectRootName().length === 0 || sidebar.normalizedProjectNodes().length === 0
                        width: parent.width
                        height: 64
                        text: sidebar.projectRootName().length === 0
                            ? sidebar.noProjectText() + "\n" + sidebar.noProjectHint()
                            : (i18n ? i18n.t("sidebar.noProjectFiles") : "No project files")
                        color: themeSubText
                        font.pixelSize: themeSmallFontSize
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                        leftPadding: 8
                    }
                }
            }
        }
    }
}
