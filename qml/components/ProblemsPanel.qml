import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: problemsPanel

    property var theme: null
    property var i18n: null
    property var backend: null
    property string stateName: "idle"
    property string statusMessage: "Project loaded successfully"
    property string logText: ""
    property string projectName: ""
    property string currentFileName: ""
    property string compilerEngine: "xelatex"
    property var problems: []
    property bool showRawLog: false
    property string copyStatus: ""
    readonly property string generatedReport: buildErrorReport()

    signal problemClicked(string file, int line)

    property color themePanel: theme ? theme.panel : "#0D1728"
    property color themePanelSoft: theme ? theme.panelSoft : "#0C1627"
    property color themeCard: theme ? theme.card : "#13233D"
    property color themeBorder: theme ? theme.border : "#17263D"
    property color themeText: theme ? theme.text : "#F3F7FF"
    property color themeSubText: theme ? theme.subText : "#8EA3C2"
    property color themeAccent: theme ? theme.accent : "#5BA8FF"
    property color themeHover: theme ? theme.hover : "#182842"
    property color themeSuccess: theme ? theme.success : "#3DD598"
    property color themeWarning: theme ? theme.warning : "#FFBE5C"
    property color themeError: theme ? theme.error : "#FF6B6B"
    property int themeCardRadius: theme ? theme.cardRadius : 18
    property int themeSmallFontSize: theme ? theme.smallFontSize : 11
    property int themeNormalFontSize: theme ? theme.normalFontSize : 13

    implicitHeight: 190
    radius: themeCardRadius
    color: themePanel
    border.width: 1
    border.color: themeBorder
    clip: true

    function typeColor(typeName) {
        if (typeName === "error") {
            return themeError
        }
        if (typeName === "warning") {
            return themeWarning
        }
        if (typeName === "info") {
            return themeSuccess
        }
        return themeSubText
    }

    function locationText(problem) {
        if (!problem || !problem.file || problem.file.length === 0) {
            return "-"
        }
        return problem.file + (problem.line > 0 ? ":" + problem.line : "")
    }

    function isChinese() {
        return i18n && i18n.currentLanguage === "zh"
    }

    function reportProblemType(typeName) {
        if (isChinese()) {
            if (typeName === "error") return "错误"
            if (typeName === "warning") return "警告"
            return "信息"
        }
        return typeName || "info"
    }

    function buildErrorReport() {
        var lines = []
        var zh = isChinese()
        var project = projectName.length > 0 ? projectName : "-"
        var fileName = currentFileName.length > 0 ? currentFileName : "-"
        var compiler = compilerEngine.length > 0 ? compilerEngine : "xelatex"
        var status = statusMessage.length > 0 ? statusMessage : "-"

        if (zh) {
            lines.push("LumiTeX 编译错误报告")
            lines.push("")
            lines.push("项目：" + project)
            lines.push("当前文件：" + fileName)
            lines.push("编译器：" + compiler)
            lines.push("状态：" + status)
            lines.push("")
            lines.push("问题列表：")
        } else {
            lines.push("LumiTeX Compile Report")
            lines.push("")
            lines.push("Project: " + project)
            lines.push("Current File: " + fileName)
            lines.push("Compiler: " + compiler)
            lines.push("Status: " + status)
            lines.push("")
            lines.push("Problems:")
        }

        if (problems.length === 0) {
            lines.push(zh ? "未解析到结构化错误，请查看原始日志。" : "No structured problems were parsed. Please check raw log.")
        } else {
            for (var i = 0; i < problems.length; i += 1) {
                var problem = problems[i]
                var location = locationText(problem)
                if (zh) {
                    lines.push((i + 1) + ". 【" + reportProblemType(problem.type) + "】" + location)
                } else {
                    lines.push((i + 1) + ". [" + reportProblemType(problem.type) + "] " + location)
                }
                lines.push("   " + (problem.message || ""))
                if (i < problems.length - 1) {
                    lines.push("")
                }
            }
        }

        lines.push("")
        if (zh) {
            lines.push("建议：")
            lines.push("- 优先检查上面列出的行号。")
            lines.push("- 如果是 Undefined control sequence，检查命令是否拼错或缺少宏包。")
            lines.push("- 如果是 package error，检查宏包参数和导入方式。")
        } else {
            lines.push("Suggestions:")
            lines.push("- Check the line numbers above.")
            lines.push("- If the error is \"Undefined control sequence\", check whether the LaTeX command or package is missing.")
            lines.push("- If the error is a package error, check package options and imports.")
            lines.push("")
            lines.push("Raw log is available in the application if needed.")
        }
        return lines.join("\n")
    }

    function copyReport() {
        if (backend && backend.copy_to_clipboard(generatedReport)) {
            copyStatus = i18n ? i18n.t("problems.reportCopied") : "Report copied."
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            spacing: 10

            Text {
                text: i18n ? i18n.t("problems.title") : "Problems"
                color: themeText
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            Rectangle {
                Layout.preferredWidth: 92
                Layout.preferredHeight: 22
                radius: 8
                color: themeCard

                Text {
                    anchors.centerIn: parent
                    text: i18n ? i18n.itemCount(problems.length)
                               : problems.length + " item" + (problems.length === 1 ? "" : "s")
                    color: stateName === "error" ? themeWarning : themeSubText
                    font.pixelSize: themeSmallFontSize
                    font.weight: Font.DemiBold
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                Layout.maximumWidth: parent.width * 0.52
                text: statusMessage
                color: stateName === "success" ? themeSuccess : (stateName === "error" ? themeWarning : themeSubText)
                font.pixelSize: 12
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 360
                radius: 10
                color: themePanelSoft
                border.width: 1
                border.color: themeBorder
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: i18n ? i18n.t("problems.structured") : "STRUCTURED MESSAGES"
                        color: themeSubText
                        font.pixelSize: themeSmallFontSize
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    ListView {
                        id: problemsList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: problems
                        spacing: 8
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }

                        delegate: Rectangle {
                            id: problemRow

                            required property var modelData

                            width: ListView.view ? ListView.view.width : 0
                            implicitHeight: problemContent.implicitHeight + 20
                            radius: 9
                            color: rowMouse.containsMouse ? themeHover : themePanel
                            border.width: 1
                            border.color: themeBorder

                            ColumnLayout {
                                id: problemContent
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                anchors.topMargin: 10
                                spacing: 7

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Rectangle {
                                        Layout.preferredWidth: 7
                                        Layout.preferredHeight: 7
                                        radius: 4
                                        color: typeColor(problemRow.modelData.type)
                                    }

                                    Text {
                                        text: i18n ? i18n.problemType(problemRow.modelData.type) : problemRow.modelData.type
                                        color: typeColor(problemRow.modelData.type)
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        Layout.preferredWidth: 64
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: locationText(problemRow.modelData)
                                        color: themeSubText
                                        font.pixelSize: themeSmallFontSize
                                        elide: Text.ElideMiddle
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: i18n ? i18n.status(problemRow.modelData.message) : problemRow.modelData.message
                                    color: themeText
                                    font.pixelSize: 12
                                    lineHeight: 1.18
                                    wrapMode: Text.WordWrap
                                }
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: problemRow.modelData.line > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: problemsPanel.problemClicked(problemRow.modelData.file, problemRow.modelData.line)
                            }
                        }

                        Text {
                            visible: problems.length === 0
                            anchors.centerIn: parent
                            width: Math.max(160, parent.width - 36)
                            text: logText.length > 0 ? logText : (i18n ? i18n.t("problems.noMessages") : "No compiler messages yet.")
                            color: themeSubText
                            font.family: Qt.platform.os === "windows" ? "Consolas" : "Monospace"
                            font.pixelSize: 11
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: Math.min(380, Math.max(260, problemsPanel.width * 0.34))
                Layout.minimumWidth: 240
                Layout.maximumWidth: 520
                Layout.fillHeight: true
                radius: 10
                color: themePanelSoft
                border.width: 1
                border.color: themeBorder
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: showRawLog
                                  ? (i18n ? i18n.t("problems.rawLog") : "RAW LOG")
                                  : (i18n ? i18n.t("problems.errorReport") : "ERROR REPORT")
                            color: themeSubText
                            font.pixelSize: themeSmallFontSize
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        AppButton {
                            theme: problemsPanel.theme
                            active: showRawLog
                            text: showRawLog
                                  ? (i18n ? i18n.t("problems.reportView") : "Error Report")
                                  : (i18n ? i18n.t("problems.rawLogView") : "Raw Log")
                            onClicked: showRawLog = !showRawLog
                        }

                        AppButton {
                            theme: problemsPanel.theme
                            text: i18n ? i18n.t("problems.copyReport") : "Copy Report"
                            onClicked: copyReport()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 8
                        color: themePanel
                        border.width: 1
                        border.color: themeBorder
                        clip: true

                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: 10
                            clip: true
                            ScrollBar.vertical.policy: ScrollBar.AsNeeded
                            ScrollBar.horizontal.policy: ScrollBar.AsNeeded

                            TextArea {
                                id: reportTextArea
                                width: parent.width
                                text: showRawLog
                                      ? (logText.length > 0 ? logText : (i18n ? i18n.t("problems.rawPlaceholder") : "Raw LaTeX log will appear here after compile."))
                                      : generatedReport
                                color: themeSubText
                                selectedTextColor: "#FFFFFF"
                                selectionColor: theme && theme.darkMode ? themeHover : themeAccent
                                readOnly: true
                                selectByMouse: true
                                wrapMode: TextEdit.Wrap
                                font.family: Qt.platform.os === "windows" ? "Consolas" : "Monospace"
                                font.pixelSize: 10
                                background: Rectangle {
                                    color: "transparent"
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: copyStatus.length > 0
                        text: copyStatus
                        color: themeSuccess
                        font.pixelSize: themeSmallFontSize
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
