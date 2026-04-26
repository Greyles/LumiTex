import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Rectangle {
    id: editorPanelRoot

    property var theme: null
    property var i18n: null
    property var backend: null
    property string editorText: ""
    property string fileName: "main.tex"
    property alias currentText: editor.text
    property string editorFont: "Consolas"
    property int editorFontSize: 15
    property bool lineWrapEnabled: false
    property string monoFontFamily: Qt.platform.os === "windows" ? "Consolas" : "JetBrains Mono, Monospace"
    property bool modified: false
    property bool loadingFile: false
    property int currentLine: currentLineNumber
    property int totalLines: totalLineCount
    property int currentLineNumber: 1
    property int totalLineCount: 1
    property string lineNumbersCache: "1"
    property bool largeFileMode: false
    property int lastFindIndex: -1
    property string findMessage: ""
    property bool findModeActive: false
    property var findMatches: []
    property int currentFindMatchIndex: -1
    property int maxFindMatches: 500
    property bool findMatchesTruncated: false
    property string lastFindQuery: ""
    property int completionTokenStart: -1
    property var completionSuggestions: []
    readonly property var completionItems: [
        { command: "\\section{}", trigger: "\\section", insertText: "\\section{|}", description: "Section heading", descriptionZh: "一级标题" },
        { command: "\\subsection{}", trigger: "\\subsection", insertText: "\\subsection{|}", description: "Subsection heading", descriptionZh: "二级标题" },
        { command: "\\subsubsection{}", trigger: "\\subsubsection", insertText: "\\subsubsection{|}", description: "Subsubsection heading", descriptionZh: "三级标题" },
        { command: "\\paragraph{}", trigger: "\\paragraph", insertText: "\\paragraph{|}", description: "Paragraph heading", descriptionZh: "段落标题" },
        { command: "\\begin{}", trigger: "\\begin", insertText: "\\begin{|}", description: "Begin environment", descriptionZh: "开始环境" },
        { command: "\\end{}", trigger: "\\end", insertText: "\\end{|}", description: "End environment", descriptionZh: "结束环境" },
        { command: "\\cite{}", trigger: "\\cite", insertText: "\\cite{|}", description: "Citation", descriptionZh: "引用文献" },
        { command: "\\ref{}", trigger: "\\ref", insertText: "\\ref{|}", description: "Cross reference", descriptionZh: "交叉引用" },
        { command: "\\label{}", trigger: "\\label", insertText: "\\label{|}", description: "Label", descriptionZh: "标签" },
        { command: "\\textbf{}", trigger: "\\textbf", insertText: "\\textbf{|}", description: "Bold text", descriptionZh: "粗体文本" },
        { command: "\\textit{}", trigger: "\\textit", insertText: "\\textit{|}", description: "Italic text", descriptionZh: "斜体文本" },
        { command: "\\emph{}", trigger: "\\emph", insertText: "\\emph{|}", description: "Emphasized text", descriptionZh: "强调文本" },
        { command: "\\includegraphics{}", trigger: "\\includegraphics", insertText: "\\includegraphics{|}", description: "Include image", descriptionZh: "插入图片" },
        { command: "\\item", trigger: "\\item", insertText: "\\item |", description: "List item", descriptionZh: "列表项" },
        { command: "\\usepackage{}", trigger: "\\usepackage", insertText: "\\usepackage{|}", description: "Load package", descriptionZh: "加载宏包" },
        {
            command: "figure",
            trigger: "\\figure",
            insertText: "\\begin{figure}[htbp]\n    \\centering\n    \\includegraphics[width=0.8\\linewidth]{|}\n    \\caption{}\n    \\label{fig:}\n\\end{figure}",
            description: "Figure environment",
            descriptionZh: "图片环境"
        },
        {
            command: "table",
            trigger: "\\table",
            insertText: "\\begin{table}[htbp]\n    \\centering\n    \\caption{}\n    \\label{tab:}\n    \\begin{tabular}{c c}\n        \\hline\n        Column 1 & Column 2 \\\\\n        \\hline\n    \\end{tabular}\n\\end{table}",
            description: "Table environment",
            descriptionZh: "表格环境"
        },
        {
            command: "equation",
            trigger: "\\equation",
            insertText: "\\begin{equation}\n    |\n\\end{equation}",
            description: "Equation environment",
            descriptionZh: "公式环境"
        },
        {
            command: "itemize",
            trigger: "\\itemize",
            insertText: "\\begin{itemize}\n    \\item |\n\\end{itemize}",
            description: "Bulleted list",
            descriptionZh: "无序列表"
        },
        {
            command: "enumerate",
            trigger: "\\enumerate",
            insertText: "\\begin{enumerate}\n    \\item |\n\\end{enumerate}",
            description: "Numbered list",
            descriptionZh: "有序列表"
        }
    ]

    property color themePanel: theme ? theme.panel : "#0D1728"
    property color themePanelSoft: theme ? theme.panelSoft : "#0C1627"
    property color themeCard: theme ? theme.card : "#13233D"
    property color themeBorder: theme ? theme.border : "#17263D"
    property color themeText: theme ? theme.text : "#F3F7FF"
    property color themeSubText: theme ? theme.subText : "#8EA3C2"
    property color themeAccent: theme ? theme.accent : "#5BA8FF"
    property color themeSuccess: theme ? theme.success : "#3DD598"
    property color themeWarning: theme ? theme.warning : "#FFBE5C"
    property color themeEditorBackground: theme ? theme.editorBackground : "#101C31"
    property color themeLineHighlight: theme ? theme.lineHighlight : "#15243A"
    property color themeHover: theme ? theme.hover : "#182842"
    property int themeCardRadius: theme ? theme.cardRadius : 18
    property int themeButtonRadius: theme ? theme.buttonRadius : 12
    property int themeSmallFontSize: theme ? theme.smallFontSize : 11
    property int themeNormalFontSize: theme ? theme.normalFontSize : 13

    signal textChangedByUser(string text)
    signal imageImportWarning(string message)

    onThemeChanged: Qt.callLater(refreshSyntaxHighlighter)
    onLoadingFileChanged: {
        if (loadingFile) {
            findDebounceTimer.stop()
            hideCompletion()
            if (typeof latexHighlighter !== "undefined" && latexHighlighter && latexHighlighter.detach) {
                latexHighlighter.detach()
            }
        } else {
            updateEditorMetrics()
            Qt.callLater(refreshSyntaxHighlighter)
        }
    }

    Connections {
        target: editorPanelRoot.theme
        ignoreUnknownSignals: true

        function onDarkModeChanged() {
            editorPanelRoot.refreshSyntaxHighlighter()
        }
    }

    Timer {
        id: findDebounceTimer
        interval: 220
        repeat: false
        onTriggered: rebuildFindMatches()
    }

    Timer {
        id: metricsDebounceTimer
        interval: 160
        repeat: false
        onTriggered: updateEditorMetrics()
    }

    function markSaved() {
        modified = false
    }

    function markLoaded() {
        modified = false
        lastFindIndex = -1
        findMessage = ""
        findMatches = []
        currentFindMatchIndex = -1
        findMatchesTruncated = false
        if (findField.text.length > 0) {
            findField.clear()
        }
        clearFindSelection(false)
        hideCompletion()
        updateEditorMetrics()
    }

    function refreshSyntaxHighlighter() {
        if (typeof latexHighlighter === "undefined" || !latexHighlighter || !editor.textDocument) {
            return
        }

        if (largeFileMode || loadingFile) {
            if (latexHighlighter.detach) {
                latexHighlighter.detach()
            }
            return
        }

        latexHighlighter.attach(editor.textDocument)
        latexHighlighter.setDarkMode(theme ? theme.darkMode : true)
    }

    function beginExternalLoad() {
        findDebounceTimer.stop()
        metricsDebounceTimer.stop()
        hideCompletion()
        if (findField.text.length > 0) {
            findField.clear()
        }
        clearFindSelection(false)
    }

    function countLines(textValue) {
        var count = 1
        for (var i = 0; i < textValue.length; i += 1) {
            if (textValue.charAt(i) === "\n") {
                count += 1
            }
        }
        return count
    }

    function buildLineNumbers(count) {
        var numbers = []
        for (var i = 1; i <= count; i += 1) {
            numbers.push(i)
        }
        return numbers.join("\n")
    }

    function updateEditorMetrics() {
        var wasLargeFile = largeFileMode
        totalLineCount = Math.max(1, countLines(editor.text))
        lineNumbersCache = buildLineNumbers(totalLineCount)
        currentLineNumber = lineForPosition(editor.cursorPosition)
        largeFileMode = editor.text.length > 200000 || totalLineCount > 3000
        if (largeFileMode !== wasLargeFile) {
            Qt.callLater(refreshSyntaxHighlighter)
        }
    }

    function scheduleFindRebuild() {
        findDebounceTimer.restart()
    }

    function scheduleEditorMetricsUpdate() {
        metricsDebounceTimer.restart()
    }

    function clearFindSelection(preserveFindFocus) {
        findDebounceTimer.stop()
        findMatches = []
        currentFindMatchIndex = -1
        lastFindIndex = -1
        findMatchesTruncated = false
        lastFindQuery = ""
        if (editor.selectionStart !== editor.selectionEnd) {
            editor.select(editor.cursorPosition, editor.cursorPosition)
        }
        updateFindMessage()
        if (preserveFindFocus === true) {
            Qt.callLater(function() {
                findField.forceActiveFocus()
            })
        }
    }

    function updateFindMessage() {
        if (findField.text.length === 0) {
            findMessage = ""
            return
        }

        if (findMatches.length === 0) {
            findMessage = "0 / 0"
            return
        }

        var currentNumber = currentFindMatchIndex >= 0 ? currentFindMatchIndex + 1 : 0
        findMessage = currentNumber + " / " + findMatches.length + (findMatchesTruncated ? "+" : "")
    }

    function findTooManyMessage() {
        return i18n ? i18n.t("editor.tooManyMatches") : "Too many matches, showing first 500."
    }

    function rebuildFindMatches() {
        if (loadingFile) {
            return
        }

        var query = findField.text
        var matches = []
        currentFindMatchIndex = -1
        lastFindIndex = -1
        findMatchesTruncated = false
        lastFindQuery = query

        if (query.length === 0) {
            clearFindSelection(true)
            updateFindMessage()
            return
        }

        var step = Math.max(1, query.length)
        var index = editor.text.indexOf(query, 0)
        while (index >= 0) {
            if (matches.length >= maxFindMatches) {
                findMatchesTruncated = true
                break
            }
            matches.push(index)
            index = editor.text.indexOf(query, index + step)
        }

        findMatches = matches
        if (findMatches.length === 0) {
            Qt.callLater(function() {
                findField.forceActiveFocus()
            })
            updateFindMessage()
            return
        }

        updateFindMessage()
        Qt.callLater(function() {
            findField.forceActiveFocus()
        })
    }

    function selectFindMatch(matchIndex, keepFindFocus) {
        if (findMatches.length === 0 || matchIndex < 0) {
            currentFindMatchIndex = -1
            lastFindIndex = -1
            updateFindMessage()
            return
        }

        currentFindMatchIndex = matchIndex % findMatches.length
        var start = findMatches[currentFindMatchIndex]
        var end = start + findField.text.length
        editor.cursorPosition = end
        editor.select(start, end)
        lastFindIndex = start
        updateFindMessage()

        if (keepFindFocus === true || findModeActive || findField.activeFocus) {
            Qt.callLater(function() {
                findField.forceActiveFocus()
            })
        }
    }

    function hideCompletion() {
        completionSuggestions = []
        completionTokenStart = -1
    }

    function updateCompletion() {
        if (loadingFile || largeFileMode || !editor.activeFocus || findModeActive) {
            hideCompletion()
            return
        }

        var beforeCursor = editor.text.substring(0, editor.cursorPosition)
        var tokenMatch = beforeCursor.match(/\\[A-Za-z]*$/)
        if (!tokenMatch) {
            hideCompletion()
            return
        }

        var token = tokenMatch[0]
        var matches = []
        for (var i = 0; i < completionItems.length; i += 1) {
            var item = completionItems[i]
            if (item.trigger.indexOf(token) === 0) {
                matches.push(item)
            }
        }

        if (matches.length === 0) {
            hideCompletion()
            return
        }

        completionTokenStart = editor.cursorPosition - token.length
        completionSuggestions = matches
    }

    function acceptCompletion(item) {
        if (!item || completionTokenStart < 0) {
            return
        }

        var start = completionTokenStart
        var end = editor.cursorPosition
        var insertText = item.insertText || item.command || ""
        var markerIndex = insertText.indexOf("|")
        if (markerIndex >= 0) {
            insertText = insertText.slice(0, markerIndex) + insertText.slice(markerIndex + 1)
        }

        editor.remove(start, end)
        editor.insert(start, insertText)
        editor.cursorPosition = start + (markerIndex >= 0 ? markerIndex : insertText.length)
        modified = true
        hideCompletion()
        editor.forceActiveFocus()
    }

    function lineForPosition(position) {
        var line = 1
        var limit = Math.min(position, editor.text.length)
        for (var i = 0; i < limit; i += 1) {
            if (editor.text.charAt(i) === "\n") {
                line += 1
            }
        }
        return line
    }

    function lineNumbersText() {
        return lineNumbersCache
    }

    function jumpToLine(lineNumber) {
        if (lineNumber < 1) {
            return
        }

        var targetLine = Math.max(1, lineNumber)
        var index = 0
        var current = 1
        while (current < targetLine && index < editor.text.length) {
            var nextIndex = editor.text.indexOf("\n", index)
            if (nextIndex === -1) {
                index = editor.text.length
                break
            }
            index = nextIndex + 1
            current += 1
        }

        editor.forceActiveFocus()
        editor.cursorPosition = index
    }

    function findNext(keepFindFocus) {
        var query = findField.text
        if (query.length === 0) {
            findMessage = ""
            clearFindSelection()
            return
        }

        if (lastFindQuery !== query) {
            rebuildFindMatches()
        }

        if (findMatches.length === 0) {
            return
        }

        var nextIndex = currentFindMatchIndex < 0 ? 0 : (currentFindMatchIndex + 1) % findMatches.length
        selectFindMatch(nextIndex, keepFindFocus)
    }

    function insertSnippet(snippet, mode) {
        if (mode === "figure") {
            imageFileDialog.open()
            return
        }

        editor.forceActiveFocus()

        var start = Math.min(editor.selectionStart, editor.selectionEnd)
        var end = Math.max(editor.selectionStart, editor.selectionEnd)
        var selectedText = start !== end ? editor.selectedText : ""
        var textToInsert = snippet

        if (mode === "section") {
            textToInsert = "\\section{" + (selectedText.length > 0 ? selectedText : "Title") + "}\n"
        } else if (mode === "subsection") {
            textToInsert = "\\subsection{" + (selectedText.length > 0 ? selectedText : "Title") + "}\n"
        }

        if (start !== end) {
            editor.remove(start, end)
            editor.insert(start, textToInsert)
            editor.cursorPosition = start + textToInsert.length
        } else {
            var insertAt = editor.cursorPosition >= 0 ? editor.cursorPosition : editor.text.length
            editor.insert(insertAt, textToInsert)
            editor.cursorPosition = insertAt + textToInsert.length
        }

        modified = true
    }

    function insertImportedFigure(relativePath, fileName) {
        var labelBase = sanitizeLabel(fileName)
        var snippet = "\\begin{figure}[htbp]\n"
            + "    \\centering\n"
            + "    \\includegraphics[width=0.8\\linewidth]{" + relativePath + "}\n"
            + "    \\caption{Figure caption.}\n"
            + "    \\label{fig:" + labelBase + "}\n"
            + "\\end{figure}\n"
        insertSnippet(snippet, "insert")
        editor.forceActiveFocus()

        if (!hasGraphicxPackage()) {
            imageImportWarning("The graphicx package is required to include images.")
        }
    }

    function hasGraphicxPackage() {
        return /\\usepackage(?:\[[^\]]*\])?\{[^}]*graphicx[^}]*\}/.test(editor.text)
    }

    function sanitizeLabel(fileName) {
        var baseName = fileName
        var dotIndex = baseName.lastIndexOf(".")
        if (dotIndex > 0) {
            baseName = baseName.substring(0, dotIndex)
        }
        baseName = baseName.replace(/[^A-Za-z0-9]+/g, "_")
        baseName = baseName.replace(/^_+|_+$/g, "")
        return baseName.length > 0 ? baseName : "image"
    }

    FileDialog {
        id: imageFileDialog
        title: i18n && i18n.currentLanguage === "zh" ? "选择图片" : "Choose Image"
        fileMode: FileDialog.OpenFile
        nameFilters: [
            "Images (*.png *.jpg *.jpeg *.pdf *.eps *.svg)",
            "PNG (*.png)",
            "JPEG (*.jpg *.jpeg)",
            "PDF (*.pdf)",
            "EPS (*.eps)",
            "SVG (*.svg)"
        ]

        onAccepted: {
            if (!backend) {
                return
            }

            var result = backend.import_image(selectedFile.toString())
            if (result && result.success === true) {
                insertImportedFigure(result.relative_path, result.file_name)
            }
        }
    }

    radius: themeCardRadius
    color: themePanel
    border.width: 1
    border.color: themeBorder

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 58
            radius: themeCardRadius
            color: themePanelSoft
            border.width: 1
            border.color: themeBorder

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                Text {
                    text: fileName
                    color: themeText
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.preferredWidth: 160
                }

                Rectangle {
                    Layout.preferredWidth: loadingFile ? 96 : (modified ? 84 : 64)
                    Layout.preferredHeight: 24
                    radius: themeButtonRadius
                    color: loadingFile
                        ? (theme && theme.darkMode ? "#172A45" : "#E7F0FB")
                        : (modified ? (theme && theme.darkMode ? "#2F2413" : "#FFF5DF") : (theme && theme.darkMode ? "#12261E" : "#E8F7EF"))

                    Text {
                        anchors.centerIn: parent
                        text: loadingFile ? (i18n ? i18n.t("editor.loadingFile") : "Loading file...")
                                       : (modified ? (i18n ? i18n.t("editor.modified") : "Modified")
                                       : (i18n ? i18n.t("editor.saved") : "Saved")
                                       )
                        color: loadingFile ? themeAccent : (modified ? themeWarning : themeSuccess)
                        font.pixelSize: themeSmallFontSize
                        font.weight: Font.DemiBold
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    radius: themeButtonRadius
                    color: themeEditorBackground
                    border.width: 1
                    border.color: findField.activeFocus ? themeAccent : themeBorder

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: i18n ? i18n.t("editor.find") : "Find"
                            color: themeSubText
                            font.pixelSize: 12
                        }

                        TextField {
                            id: findField
                            Layout.fillWidth: true
                            color: themeText
                            placeholderText: i18n ? i18n.t("editor.findPlaceholder") : "command, label, word"
                            placeholderTextColor: themeSubText
                            selectByMouse: true
                            background: Rectangle { color: "transparent" }
                            onActiveFocusChanged: {
                                console.log("Find activeFocus changed:", findField.activeFocus)
                                if (activeFocus) {
                                    findModeActive = true
                                    findDebounceTimer.stop()
                                    hideCompletion()
                                }
                            }
                            TapHandler {
                                onTapped: {
                                    console.log("Find clicked")
                                    findField.forceActiveFocus()
                                }
                            }
                            onTextChanged: {
                                if (loadingFile) {
                                    return
                                }
                                scheduleFindRebuild()
                            }
                            Keys.onReturnPressed: findNext(true)
                            Keys.onEnterPressed: findNext(true)
                            Keys.onEscapePressed: {
                                if (text.length > 0) {
                                    clear()
                                    findMessage = ""
                                    lastFindIndex = -1
                                    clearFindSelection(true)
                                    forceActiveFocus()
                                } else {
                                    findModeActive = false
                                    editor.forceActiveFocus()
                                }
                            }
                        }

                        Text {
                            text: findMessage
                            color: findMessage === "0 / 0" || findMatchesTruncated ? themeWarning : themeSubText
                            font.pixelSize: themeSmallFontSize
                            Layout.preferredWidth: 64
                            elide: Text.ElideRight
                            ToolTip.visible: findMatchesTruncated && statusHover.containsMouse
                            ToolTip.text: findTooManyMessage()

                            MouseArea {
                                id: statusHover
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }
                        }

                        AppButton {
                            theme: editorPanelRoot.theme
                            text: i18n ? i18n.t("editor.next") : "Next"
                            enabled: findField.text.length > 0
                            onClicked: findNext(true)
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 92
                    Layout.preferredHeight: 30
                    radius: themeButtonRadius
                    color: themePanelSoft
                    border.width: 1
                    border.color: themeBorder

                    Text {
                        anchors.centerIn: parent
                        text: "Ln " + currentLine + " / " + totalLines
                        color: themeSubText
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        InsertToolbar {
            Layout.fillWidth: true
            theme: editorPanelRoot.theme
            i18n: editorPanelRoot.i18n
            onInsertRequested: function(snippet, mode) {
                insertSnippet(snippet, mode)
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: themeCardRadius
            color: themeEditorBackground
            border.width: 1
            border.color: themeBorder

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.preferredWidth: 56
                    Layout.fillHeight: true
                    radius: themeCardRadius
                    color: themePanelSoft
                    border.width: 1
                    border.color: themeBorder
                    clip: true

                    Text {
                        anchors.top: parent.top
                        anchors.topMargin: 22 - (editorScroll && editorScroll.contentItem ? editorScroll.contentItem.contentY : 0)
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        text: lineNumbersText()
                        color: themeSubText
                        font.family: editorFont.length > 0 ? editorFont : monoFontFamily
                        font.pixelSize: Math.max(12, editorFontSize - 1)
                        lineHeight: 1.46
                        horizontalAlignment: Text.AlignRight
                        z: 1
                    }

                    Rectangle {
                        width: 38
                        height: 22
                        radius: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        y: Math.max(16, 16 + (currentLine - 1) * 22 - (editorScroll && editorScroll.contentItem ? editorScroll.contentItem.contentY : 0))
                        color: themeHover
                        opacity: 0.75
                        z: 0
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: Math.max(22, editor.cursorRectangle.height + 6)
                        y: Math.max(0, editor.cursorRectangle.y - (editorScroll && editorScroll.contentItem ? editorScroll.contentItem.contentY : 0) - 3)
                        color: themeLineHighlight
                        opacity: 0.72
                        radius: 8
                    }

                    ScrollView {
                        anchors.fill: parent
                        id: editorScroll
                        clip: true
                        contentWidth: Math.max(availableWidth, editor.contentWidth + editor.leftPadding + editor.rightPadding)
                        contentHeight: Math.max(availableHeight, editor.contentHeight + editor.topPadding + editor.bottomPadding)
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded
                        ScrollBar.horizontal.policy: lineWrapEnabled ? ScrollBar.AlwaysOff : ScrollBar.AsNeeded

                        TextArea {
                            id: editor
                            width: Math.max(editorScroll.availableWidth, editor.contentWidth + leftPadding + rightPadding)
                            height: Math.max(editorScroll.availableHeight, editor.contentHeight + topPadding + bottomPadding)
                            text: editorText
                            wrapMode: lineWrapEnabled ? TextEdit.Wrap : TextEdit.NoWrap
                            selectByMouse: true
                            persistentSelection: true
                            leftPadding: 22
                            rightPadding: 22
                            topPadding: 22
                            bottomPadding: 22
                            color: themeText
                            selectedTextColor: findField.text.length > 0
                                ? (theme && theme.darkMode ? "#FFFFFF" : "#2A2200")
                                : "#FFFFFF"
                            selectionColor: findField.text.length > 0
                                ? (theme && theme.darkMode ? "#B7791F" : "#FFD54F")
                                : themeAccent
                            font.family: editorFont.length > 0 ? editorFont : monoFontFamily
                            font.pixelSize: editorFontSize
                            Component.onCompleted: Qt.callLater(editorPanelRoot.refreshSyntaxHighlighter)
                            onActiveFocusChanged: {
                                console.log("Editor activeFocus changed:", editor.activeFocus)
                                if (activeFocus) {
                                    findModeActive = false
                                    if (!loadingFile) {
                                        updateCompletion()
                                    }
                                }
                            }
                            onCursorPositionChanged: {
                                currentLineNumber = lineForPosition(editor.cursorPosition)
                                if (!loadingFile) {
                                    updateCompletion()
                                }
                            }
                            onTextChanged: {
                                if (loadingFile) {
                                    updateEditorMetrics()
                                    return
                                }
                                if (text !== editorText) {
                                    modified = true
                                }
                                textChangedByUser(text)
                                scheduleEditorMetricsUpdate()
                                if (findField.text.length > 0) {
                                    scheduleFindRebuild()
                                } else {
                                    clearFindSelection(false)
                                }
                                if (!largeFileMode) {
                                    Qt.callLater(editorPanelRoot.updateCompletion)
                                } else {
                                    hideCompletion()
                                }
                            }
                            Keys.priority: Keys.BeforeItem
                            Keys.onPressed: function(event) {
                                if (!completionPopup.visible) {
                                    return
                                }

                                if (event.key === Qt.Key_Down) {
                                    completionPopup.moveSelection(1)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Up) {
                                    completionPopup.moveSelection(-1)
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Tab) {
                                    completionPopup.acceptCurrent()
                                    event.accepted = true
                                } else if (event.key === Qt.Key_Escape) {
                                    hideCompletion()
                                    event.accepted = true
                                }
                            }

                            background: Rectangle {
                                radius: themeCardRadius
                                color: "transparent"
                            }
                        }
                    }

                    Rectangle {
                        visible: loadingFile
                        anchors.centerIn: parent
                        width: Math.min(parent.width - 48, 260)
                        height: 52
                        radius: themeButtonRadius
                        color: themePanelSoft
                        border.width: 1
                        border.color: themeBorder
                        z: 30

                        Text {
                            anchors.centerIn: parent
                            text: i18n ? i18n.t("editor.loadingFile") : "Loading file..."
                            color: themeText
                            font.pixelSize: themeNormalFontSize
                            font.weight: Font.DemiBold
                        }
                    }

                    CompletionPopup {
                        id: completionPopup

                        theme: editorPanelRoot.theme
                        i18n: editorPanelRoot.i18n
                        suggestions: editorPanelRoot.completionSuggestions
                        z: 20
                        x: Math.min(
                            parent.width - width - 8,
                            Math.max(8, editor.cursorRectangle.x - (editorScroll && editorScroll.contentItem ? editorScroll.contentItem.contentX : 0) + 16)
                        )
                        y: Math.min(
                            parent.height - height - 8,
                            Math.max(8, editor.cursorRectangle.y - (editorScroll && editorScroll.contentItem ? editorScroll.contentItem.contentY : 0) + editor.cursorRectangle.height + 12)
                        )
                        onCompletionAccepted: function(item) {
                            editorPanelRoot.acceptCompletion(item)
                        }
                    }
                }
            }
        }
    }
}
