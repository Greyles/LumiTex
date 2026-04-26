import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"
import "i18n"
import "theme"

ApplicationWindow {
    id: window
    visible: true
    width: 1440
    height: 900
    minimumWidth: 1220
    minimumHeight: 760
    title: "LumiTeX"
    flags: Qt.Window | Qt.FramelessWindowHint
    color: appTheme.background

    Theme {
        id: appTheme
    }

    Strings {
        id: i18n
        currentLanguage: window.currentLanguage
    }

    property var backend: typeof appBridge !== "undefined" ? appBridge : null
    property string compileState: "idle"
    property string compileStatusMessage: backend ? backend.statusMessage : "No project opened."
    property string compileLogText: backend ? backend.compileLog : ""
    property string previewImagePath: backend ? backend.previewImagePath : ""
    property var previewImagePaths: backend ? backend.previewImagePaths : []
    property bool previewVisible: true
    property var problems: backend ? backend.problems : []
    property var projectTree: backend ? backend.projectTree : []
    property var projectFiles: backend ? backend.projectFiles : []
    property var openFiles: backend ? backend.openFiles : []
    property var templates: []
    property var appSettings: ({})
    property string currentLanguage: "zh"
    property string editorFont: "Consolas"
    property int editorFontSize: 15
    property bool editorLineWrap: false
    property string currentCompiler: "xelatex"
    property string projectName: backend ? backend.projectName : ""
    property string currentFile: backend ? backend.currentFileName : ""
    property string currentFileName: backend ? backend.currentFileName : ""
    property string currentFileType: backend ? backend.currentFileType : ""
    property string currentImageUrl: ""
    property string editorText: ""
    property bool editorModified: false
    property bool fileLoading: false

    Connections {
        target: window.backend

        function onCompileStarted() {
            window.compileState = "running"
            window.compileStatusMessage = window.backend.statusMessage
            window.compileLogText = window.backend.compileLog
            window.problems = window.backend.problems
            window.previewImagePath = ""
            window.previewImagePaths = []
            window.editorModified = false
            editorPanel.markSaved()
        }

        function onCompileFinished(success, message, logText) {
            window.compileState = success ? "success" : "error"
            window.compileStatusMessage = message
            window.compileLogText = logText
            window.problems = window.backend.problems
        }

        function onFileStatusChanged(success, message, logText) {
            window.compileState = success ? "success" : "error"
            window.compileStatusMessage = message
            window.compileLogText = logText
            if (success && message === "File saved.") {
                window.editorModified = false
                window.openFiles = window.backend.get_open_files()
                console.log("QML openFiles:", JSON.stringify(window.openFiles))
                editorPanel.markSaved()
            }
        }

        function onCurrentProjectChanged() {
            window.projectName = window.backend.projectName
            window.currentFileName = window.backend.currentFileName
            window.currentFile = window.currentFileName
            window.currentFileType = window.backend.currentFileType || ""
            window.currentImageUrl = ""
            window.editorText = ""
            window.projectTree = window.backend.get_project_tree()
            window.projectFiles = window.backend.projectFiles
            window.openFiles = window.backend.get_open_files()
            console.log("QML projectTree:", JSON.stringify(window.projectTree))
            console.log("QML openFiles:", JSON.stringify(window.openFiles))
            window.previewImagePath = ""
            window.previewImagePaths = []
            window.editorModified = false
        }

        function onProjectClosed() {
            window.resetToWelcome()
        }

        function onProjectFilesChanged() {
            window.projectFiles = window.backend.projectFiles
        }

        function onProjectTreeChanged(tree) {
            window.projectTree = tree
            console.log("QML projectTree:", JSON.stringify(window.projectTree))
        }

        function onOpenFilesChanged() {
            window.openFiles = window.backend.get_open_files()
            console.log("QML openFiles:", JSON.stringify(window.openFiles))
            window.editorModified = window.isFileModified(window.currentFileName)
        }

        function onCurrentFileChanged(relativePath) {
            window.currentFileName = relativePath
            window.currentFile = relativePath
            window.editorModified = window.isFileModified(relativePath)
        }

        function onLoadFileStarted(relativePath) {
            window.fileLoading = true
            window.currentFileName = relativePath
            window.currentFile = relativePath
            window.currentFileType = "text"
            window.currentImageUrl = ""
            window.editorModified = false
            window.compileStatusMessage = "Loading file..."
            window.compileLogText = relativePath
            if (editorPanel.visible) {
                editorPanel.beginExternalLoad()
            }
            window.editorText = ""
        }

        function onCurrentFileTypeChanged() {
            window.currentFileType = window.backend.currentFileType || ""
            if (window.currentFileType !== "image") {
                window.currentImageUrl = ""
            }
            if (window.currentFileType !== "text") {
                window.editorModified = false
                window.fileLoading = false
            }
        }

        function onCurrentFileLoaded(relativePath, content) {
            window.fileLoading = true
            window.currentFileName = relativePath
            window.currentFile = relativePath
            window.currentFileType = "text"
            window.currentImageUrl = ""
            editorPanel.beginExternalLoad()
            window.editorText = content
            window.openFiles = window.backend.get_open_files()
            console.log("QML openFiles:", JSON.stringify(window.openFiles))
            window.editorModified = window.isFileModified(relativePath)
            Qt.callLater(function() {
                window.fileLoading = false
                if (window.editorModified) {
                    editorPanel.modified = true
                } else {
                    editorPanel.markLoaded()
                }
            })
        }

        function onImageFileLoaded(relativePath, imageUrl) {
            window.fileLoading = false
            window.currentFileName = relativePath
            window.currentFile = relativePath
            window.currentFileType = "image"
            window.currentImageUrl = imageUrl
            window.editorModified = false
            window.openFiles = window.backend.get_open_files()
            console.log("QML imageFileLoaded:", relativePath, imageUrl)
            console.log("QML openFiles:", JSON.stringify(window.openFiles))
        }

        function onProblemsUpdated(problems) {
            window.problems = problems
        }

        function onSettingsChanged(settings) {
            window.applySettings(settings)
        }

        function onPreviewPagesUpdated(imagePaths) {
            window.previewImagePaths = imagePaths
            window.previewImagePath = imagePaths.length > 0 ? imagePaths[0] : ""
        }

        function onLanguageChanged(language) {
            window.currentLanguage = language === "zh" ? "zh" : "en"
        }

        function onPreviewUpdated(imagePath) {
            window.previewImagePath = imagePath
            if (window.previewImagePaths.length === 0 && imagePath.length > 0) {
                window.previewImagePaths = [imagePath]
            }
        }

        function onPreviewFailed(message) {
            window.compileState = "error"
            window.compileStatusMessage = message
            window.compileLogText = window.compileLogText + "\n\n" + message
        }
    }

    Component.onCompleted: {
        if (window.backend) {
            window.applySettings(window.backend.load_settings())
            window.projectName = window.backend.projectName
            window.currentFileName = window.backend.currentFileName
            window.currentFile = window.currentFileName
            window.currentFileType = window.backend.currentFileType || ""
            window.projectTree = window.backend.get_project_tree()
            window.projectFiles = window.backend.projectFiles
            window.openFiles = window.backend.get_open_files()
            window.previewImagePath = window.backend.previewImagePath
            window.previewImagePaths = window.backend.previewImagePaths
            window.templates = window.backend.list_templates()
            window.editorText = ""
            window.currentImageUrl = ""
            console.log("QML projectTree:", JSON.stringify(window.projectTree))
            console.log("QML openFiles:", JSON.stringify(window.openFiles))
        }
    }

    function applySettings(settings) {
        window.appSettings = settings || {}
        window.editorFont = window.appSettings.editorFont || "Consolas"
        window.editorFontSize = window.appSettings.fontSize || 15
        window.editorLineWrap = window.appSettings.lineWrap === true
        window.currentCompiler = window.appSettings.compilerEngine || window.appSettings.compiler || "xelatex"
        window.currentLanguage = window.appSettings.language === "zh" ? "zh" : "en"

        var themeName = String(window.appSettings.theme || "light").toLowerCase()
        if (themeName === "light") {
            appTheme.darkMode = false
        } else if (themeName === "dark") {
            appTheme.darkMode = true
        }
    }

    onCurrentLanguageChanged: console.log("[i18n] currentLanguage =", currentLanguage)

    function isFileModified(relativePath) {
        for (var i = 0; i < window.openFiles.length; i += 1) {
            if (window.openFiles[i].relativePath === relativePath) {
                return window.openFiles[i].modified === true
            }
        }
        return false
    }

    function compileCurrentDocument() {
        if (!window.backend) {
            return
        }

        var content = window.currentFileType === "text" && window.currentFileName.length > 0
            ? editorPanel.currentText
            : ""
        window.backend.compile_project(content)
    }

    function saveAndCompileCurrentDocument() {
        if (!window.backend) {
            return
        }
        if (window.projectName.length === 0 && window.currentFileName.length === 0) {
            window.backend.report_warning("No file to save.")
            return
        }
        window.compileCurrentDocument()
    }

    function resetToWelcome() {
        window.projectName = ""
        window.currentFile = ""
        window.currentFileName = ""
        window.currentFileType = ""
        window.currentImageUrl = ""
        window.editorText = ""
        window.editorModified = false
        window.fileLoading = false
        window.projectTree = []
        window.projectFiles = []
        window.openFiles = []
        window.previewImagePath = ""
        window.previewImagePaths = []
        window.problems = []
        window.compileState = "idle"
        window.compileStatusMessage = "Project closed."
        window.compileLogText = ""
    }

    Shortcut {
        sequence: StandardKey.Save
        enabled: !topCommandBar.settingsDialogOpen && !topCommandBar.newProjectDialogOpen
        onActivated: window.saveAndCompileCurrentDocument()
    }

    Rectangle {
        anchors.fill: parent
        border.width: 1
        border.color: appTheme.border
        gradient: Gradient {
            GradientStop { position: 0.0; color: appTheme.darkMode ? "#0A1324" : "#FFFFFF" }
            GradientStop { position: 0.55; color: appTheme.background }
            GradientStop { position: 1.0; color: appTheme.darkMode ? "#091423" : "#EEF4FA" }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            width: 320
            height: 320
            radius: 160
            color: appTheme.accent
            opacity: appTheme.darkMode ? 0.14 : 0.07
            x: parent.width - width * 0.65
            y: -120
        }

        TopBar {
            id: topCommandBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 46
            windowRef: window
            theme: appTheme
            i18n: i18n
            projectName: window.projectName
            currentFileName: window.currentFileName
            fileModified: window.editorModified
            previewActive: window.previewVisible
            templates: window.templates
            settings: window.appSettings
            onThemeToggleRequested: appTheme.darkMode = !appTheme.darkMode
            onThemeSelected: function(themeName) {
                var normalizedTheme = String(themeName || "").toLowerCase()
                if (normalizedTheme === "light") {
                    appTheme.darkMode = false
                } else if (normalizedTheme === "dark") {
                    appTheme.darkMode = true
                }
            }
            onSettingsSaved: function(settings) {
                console.log("Main received settings", JSON.stringify(settings))
                window.applySettings(settings)
                if (window.backend) {
                    window.backend.save_settings(settings)
                }
            }
            onCleanAuxClicked: {
                if (window.backend) {
                    window.backend.clean_aux_files()
                }
            }
            onCloseProjectRequested: {
                if (window.backend) {
                    var result = window.backend.close_project()
                    if (result && result.success === true) {
                        window.resetToWelcome()
                    }
                }
            }
            onCreateProject: function(templateId, targetDir, projectName) {
                if (window.backend) {
                    window.backend.create_project(templateId, targetDir, projectName)
                }
            }
            onOpenProject: function(path) {
                if (window.backend) {
                    window.backend.open_project(path)
                }
            }
            onSaveClicked: {
                if (window.backend) {
                    if (window.currentFileName.length === 0) {
                        window.backend.report_warning("No file to save.")
                    } else if (window.currentFileType === "text") {
                        window.backend.save_current_file(editorPanel.currentText)
                    } else {
                        window.backend.report_warning("Image preview mode does not need saving.")
                    }
                }
            }
            onCompileClicked: {
                window.compileCurrentDocument()
            }
            onPreviewToggled: {
                window.previewVisible = !window.previewVisible
            }
        }

        SplitView {
            anchors.top: topCommandBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            anchors.topMargin: 14
            anchors.bottomMargin: 18
            orientation: Qt.Vertical
            handle: Rectangle {
                implicitHeight: 8
                color: SplitHandle.pressed ? appTheme.accent : (SplitHandle.hovered ? appTheme.hover : "transparent")

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: 1
                    color: appTheme.border
                }
            }

            SplitView {
                SplitView.fillHeight: true
                SplitView.minimumHeight: 420
                orientation: Qt.Horizontal
                handle: Rectangle {
                    implicitWidth: 8
                    color: SplitHandle.pressed ? appTheme.accent : (SplitHandle.hovered ? appTheme.hover : "transparent")

                    Rectangle {
                        anchors.centerIn: parent
                        width: 1
                        height: parent.height
                        color: appTheme.border
                    }
                }

                Sidebar {
                    SplitView.preferredWidth: 250
                    SplitView.minimumWidth: 180
                    SplitView.maximumWidth: 420
                    theme: appTheme
                    i18n: i18n
                    projectName: window.projectName
                    openFiles: window.openFiles
                    projectTree: window.projectTree
                    currentFile: window.currentFile
                    currentFilePath: window.currentFileName
                    onOpenFileRequested: function(relativePath) {
                        if (window.backend) {
                            window.backend.load_file(relativePath)
                        }
                    }
                    onUnsupportedFileRequested: function(relativePath) {
                        if (window.backend) {
                            window.backend.report_warning("This file type is not supported for preview yet.")
                        }
                    }
                }

                Item {
                    id: centerPanel
                    SplitView.fillWidth: true
                    SplitView.minimumWidth: 420

                    EditorPanel {
                        id: editorPanel
                        anchors.fill: parent
                        visible: window.currentFileType === "text" && window.currentFileName.length > 0
                        theme: appTheme
                        i18n: i18n
                        backend: window.backend
                        fileName: window.currentFileName
                        editorFont: window.editorFont
                        editorFontSize: window.editorFontSize
                        lineWrapEnabled: window.editorLineWrap
                        loadingFile: window.fileLoading
                        editorText: window.editorText
                        onTextChangedByUser: function(text) {
                            if (window.currentFileType !== "text") {
                                return
                            }
                            if (window.currentFileName.length === 0) {
                                return
                            }
                            if (text !== window.editorText) {
                                window.editorModified = true
                                if (window.backend) {
                                    window.backend.update_open_file_content(window.currentFileName, text, true)
                                }
                            }
                            window.editorText = text
                        }
                        onImageImportWarning: function(message) {
                            if (window.backend) {
                                window.backend.report_warning(message)
                            }
                        }
                    }

                    ImagePreviewPanel {
                        id: imagePreviewPanel
                        anchors.fill: parent
                        visible: window.currentFileType === "image"
                        theme: appTheme
                        i18n: i18n
                        fileName: window.currentFileName
                        imageUrl: window.currentImageUrl
                    }

                    Rectangle {
                        id: welcomePanel
                        anchors.fill: parent
                        visible: window.currentFileName.length === 0 && window.currentFileType !== "image"
                        radius: appTheme.cardRadius
                        color: appTheme.panel
                        border.width: 1
                        border.color: appTheme.border

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: Math.min(parent.width - 64, 520)
                            spacing: 18

                            Text {
                                Layout.fillWidth: true
                                text: "LumiTeX"
                                color: appTheme.text
                                font.pixelSize: 34
                                font.weight: Font.Black
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: i18n.t("welcome.editorSubtitle")
                                color: appTheme.subText
                                font.pixelSize: 15
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: i18n.t("welcome.getStarted")
                                color: appTheme.text
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                horizontalAlignment: Text.AlignHCenter
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 10

                                AppButton {
                                    theme: appTheme
                                    active: true
                                    text: i18n.t("topbar.newProject")
                                    onClicked: topCommandBar.openNewProjectDialog()
                                }

                                AppButton {
                                    theme: appTheme
                                    text: i18n.t("topbar.openProject")
                                    onClicked: topCommandBar.openProjectDialog()
                                }
                            }
                        }
                    }
                }

                PdfPreview {
                    id: pdfPreviewPanel
                    visible: window.previewVisible
                    SplitView.preferredWidth: window.previewVisible ? 560 : 0
                    SplitView.minimumWidth: window.previewVisible ? 360 : 0
                    SplitView.maximumWidth: window.previewVisible ? 860 : 0
                    theme: appTheme
                    i18n: i18n
                    previewImagePath: window.previewImagePath
                    previewImagePaths: window.previewImagePaths
                }
            }

            ProblemsPanel {
                SplitView.preferredHeight: 180
                SplitView.minimumHeight: 100
                SplitView.maximumHeight: 520
                theme: appTheme
                i18n: i18n
                backend: window.backend
                stateName: window.compileState
                statusMessage: i18n.status(window.compileStatusMessage)
                logText: window.compileLogText
                projectName: window.projectName
                currentFileName: window.currentFileName
                compilerEngine: window.currentCompiler
                problems: window.problems
                onProblemClicked: function(file, line) {
                    if (line < 1) {
                        return
                    }
                    if (file.length > 0 && file !== window.currentFileName && window.backend) {
                        window.backend.load_file(file)
                    }
                    Qt.callLater(function() {
                        editorPanel.jumpToLine(line)
                    })
                }
            }
        }
    }
}
