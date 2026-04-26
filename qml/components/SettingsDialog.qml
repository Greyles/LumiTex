import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: dialog

    property var theme: null
    property var i18n: null
    property var settings: ({})
    property string selectedLanguage: "zh"

    signal settingsSaved(var settings)
    signal settingsSaveRequested(var settings)
    signal themeSelected(string themeName)

    function openWithSettings(currentSettings) {
        settings = currentSettings || {}
        compilerBox.currentIndex = Math.max(0, compilerBox.indexOfValue(settings.compilerEngine || "xelatex"))
        fontBox.currentIndex = Math.max(0, fontBox.indexOfValue(settings.editorFont || "Consolas"))
        fontSizeBox.currentIndex = Math.max(0, fontSizeBox.indexOfValue(settings.fontSize || 15))
        wrapSwitch.checked = settings.lineWrap === true
        themeBox.currentIndex = Math.max(0, themeBox.indexOfValue(normalizeTheme(settings.theme || "light")))
        selectedLanguage = (settings.language || "zh") === "zh" ? "zh" : "en"
        languageBox.currentIndex = languageIndex(selectedLanguage)
        open()
    }

    function trText(key) {
        return i18n ? i18n.t(key) : key
    }

    function commandPreview() {
        if (compilerBox.currentValue === "latexmk") {
            return "latexmk -pdf -interaction=nonstopmode -file-line-error main.tex"
        }
        return compilerBox.currentValue + " -interaction=nonstopmode -file-line-error main.tex"
    }

    function valueAt(comboBox, fallbackValue) {
        if (comboBox.currentValue !== undefined && comboBox.currentValue !== null) {
            return comboBox.currentValue
        }
        if (comboBox.currentIndex >= 0 && comboBox.model[comboBox.currentIndex]) {
            var item = comboBox.model[comboBox.currentIndex]
            return item.value !== undefined ? item.value : item
        }
        return fallbackValue
    }

    function languageIndex(language) {
        return language === "zh" ? 1 : 0
    }

    function languageAt(index) {
        return index === 1 ? "zh" : "en"
    }

    function normalizeTheme(themeName) {
        var normalized = String(themeName || "").toLowerCase()
        if (normalized === "dark" || normalized === "light" || normalized === "system") {
            return normalized
        }
        return "light"
    }

    modal: true
    width: 560
    height: 600
    title: trText("settings.title")
    standardButtons: Dialog.NoButton
    closePolicy: Popup.CloseOnEscape

    property color themePanel: theme ? theme.panel : "#0D1728"
    property color themePanelSoft: theme ? theme.panelSoft : "#0C1627"
    property color themeCard: theme ? theme.card : "#13233D"
    property color themeBorder: theme ? theme.border : "#213553"
    property color themeText: theme ? theme.text : "#F3F7FF"
    property color themeSubText: theme ? theme.subText : "#8EA3C2"
    property color themeAccent: theme ? theme.accent : "#5BA8FF"
    property int themeRadius: theme ? theme.cardRadius : 18

    background: Rectangle {
        radius: themeRadius
        color: themePanel
        border.width: 1
        border.color: themeBorder
    }

    contentItem: ColumnLayout {
        spacing: 14

        Text {
            text: trText("settings.title")
            color: themeText
            font.pixelSize: theme ? theme.titleFontSize : 18
            font.weight: Font.Bold
        }

        ScrollView {
            id: settingsScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: settingsScroll.availableWidth
                spacing: 14

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 118
                    radius: 14
                    color: themeCard
                    border.width: 1
                    border.color: themeBorder

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        Text { text: trText("settings.compiler"); color: themeText; font.weight: Font.DemiBold }
                        Text { text: trText("settings.compilerEngine"); color: themeSubText; font.pixelSize: 11 }
                        ComboBox {
                            id: compilerBox
                            Layout.fillWidth: true
                            model: [
                                { text: "xelatex", value: "xelatex" },
                                { text: "pdflatex", value: "pdflatex" },
                                { text: "latexmk", value: "latexmk" }
                            ]
                            textRole: "text"
                            valueRole: "value"
                        }
                        Text {
                            Layout.fillWidth: true
                            text: commandPreview()
                            color: themeSubText
                            font.family: Qt.platform.os === "windows" ? "Consolas" : "Monospace"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    radius: 14
                    color: themeCard
                    border.width: 1
                    border.color: themeBorder

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        Text { text: trText("settings.editor"); color: themeText; font.weight: Font.DemiBold }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Text { text: trText("settings.editorFont"); color: themeSubText; font.pixelSize: 11 }
                                ComboBox {
                                    id: fontBox
                                    Layout.fillWidth: true
                                    model: [
                                        { text: "Consolas", value: "Consolas" },
                                        { text: "JetBrains Mono", value: "JetBrains Mono" },
                                        { text: "Courier New", value: "Courier New" },
                                        { text: "Monospace", value: "Monospace" }
                                    ]
                                    textRole: "text"
                                    valueRole: "value"
                                }
                            }
                            ColumnLayout {
                                Layout.preferredWidth: 110
                                spacing: 4
                                Text { text: trText("settings.fontSize"); color: themeSubText; font.pixelSize: 11 }
                                ComboBox {
                                    id: fontSizeBox
                                    Layout.fillWidth: true
                                    model: [
                                        { text: "13", value: 13 },
                                        { text: "14", value: 14 },
                                        { text: "15", value: 15 },
                                        { text: "16", value: 16 },
                                        { text: "18", value: 18 }
                                    ]
                                    textRole: "text"
                                    valueRole: "value"
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: trText("settings.lineWrap"); color: themeSubText; Layout.fillWidth: true }
                            Switch { id: wrapSwitch }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    radius: 14
                    color: themeCard
                    border.width: 1
                    border.color: themeBorder

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        Text { text: trText("settings.theme"); color: themeText; Layout.fillWidth: true; font.weight: Font.DemiBold }
                        ComboBox {
                            id: themeBox
                            Layout.preferredWidth: 170
                            model: [
                                { text: trText("settings.dark"), value: "dark" },
                                { text: trText("settings.light"), value: "light" },
                                { text: trText("settings.system"), value: "system" }
                            ]
                            textRole: "text"
                            valueRole: "value"
                            onActivated: {
                                if (currentValue !== "system") {
                                    themeSelected(currentValue)
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    radius: 14
                    color: themeCard
                    border.width: 1
                    border.color: themeBorder

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        Text {
                            text: trText("settings.language")
                            color: themeText
                            Layout.fillWidth: true
                            font.weight: Font.DemiBold
                        }
                        ComboBox {
                            id: languageBox
                            Layout.preferredWidth: 170
                            model: [
                                trText("settings.english"),
                                trText("settings.chinese")
                            ]
                            onCurrentIndexChanged: selectedLanguage = languageAt(currentIndex)
                            onActivated: selectedLanguage = languageAt(currentIndex)
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            Item { Layout.fillWidth: true }
            Button { text: trText("settings.cancel"); onClicked: close() }
            Button {
                text: trText("settings.save")
                highlighted: true
                onClicked: {
                    selectedLanguage = languageAt(languageBox.currentIndex)
                    var nextSettings = {
                        compilerEngine: valueAt(compilerBox, "xelatex"),
                        compiler: valueAt(compilerBox, "xelatex"),
                        editorFont: valueAt(fontBox, "Consolas"),
                        fontSize: parseInt(valueAt(fontSizeBox, 15)),
                        lineWrap: wrapSwitch.checked,
                        theme: valueAt(themeBox, "light"),
                        language: selectedLanguage
                    }
                    console.log("Saving compiler:", nextSettings.compiler)
                    console.log("SettingsDialog save clicked", JSON.stringify(nextSettings))
                    settingsSaved(nextSettings)
                    settingsSaveRequested(nextSettings)
                    close()
                }
            }
        }
    }
}
