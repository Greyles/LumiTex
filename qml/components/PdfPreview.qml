import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: pdfPreviewRoot

    property var theme: null
    property var i18n: null
    property string previewImagePath: ""
    property var previewImagePaths: []
    property int zoomPercent: 100
    property int pageHorizontalPadding: 16
    property int pageTopPadding: 10
    property int pageSpacing: 22
    readonly property real a4Ratio: 1.414
    readonly property var displayPreviewImagePaths: previewImagePaths.length > 0
        ? previewImagePaths
        : (previewImagePath.length > 0 ? [previewImagePath] : [])
    readonly property bool hasRenderedPages: displayPreviewImagePaths.length > 0
    readonly property real fitPageWidth: Math.max(260, previewScroll.availableWidth - pageHorizontalPadding * 2)
    readonly property real calculatedPageWidth: Math.max(180, fitPageWidth * zoomPercent / 100)
    readonly property real placeholderPageHeight: calculatedPageWidth * a4Ratio

    property color themePanel: theme ? theme.panel : "#0D1728"
    property color themePanelSoft: theme ? theme.panelSoft : "#0C1627"
    property color themeBorder: theme ? theme.border : "#17263D"
    property color themeText: theme ? theme.text : "#F3F7FF"
    property color themeSubText: theme ? theme.subText : "#8EA3C2"
    property color themePdfBackground: theme ? theme.pdfBackground : "#101C31"
    property int themeCardRadius: theme ? theme.cardRadius : 18

    function clampZoom(value) {
        return Math.max(35, Math.min(300, value))
    }

    function pageCountText() {
        if (!hasRenderedPages) {
            return i18n ? i18n.t("pdf.placeholder") : "Placeholder"
        }
        if (i18n && i18n.currentLanguage === "zh") {
            return "共 " + displayPreviewImagePaths.length + " 页"
        }
        return displayPreviewImagePaths.length + (displayPreviewImagePaths.length === 1 ? " page" : " pages")
    }

    function fitWidth() {
        zoomPercent = 100
    }

    onPreviewImagePathChanged: Qt.callLater(fitWidth)
    onPreviewImagePathsChanged: Qt.callLater(fitWidth)

    radius: 0
    color: "transparent"
    border.width: 0
    border.color: "transparent"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            radius: themeCardRadius
            color: themePanelSoft
            border.width: 1
            border.color: themeBorder

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16

                Text {
                    text: i18n ? i18n.t("pdf.preview") : "PDF Preview"
                    color: themeText
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Item { Layout.fillWidth: true }

                AppButton {
                    theme: pdfPreviewRoot.theme
                    compact: true
                    text: "-"
                    onClicked: zoomPercent = clampZoom(zoomPercent - 10)
                }

                Text {
                    text: zoomPercent === 100 ? (i18n ? i18n.t("pdf.fit") : "Fit") : zoomPercent + "%"
                    color: themeSubText
                    font.pixelSize: 12
                    Layout.preferredWidth: 44
                    horizontalAlignment: Text.AlignHCenter
                }

                AppButton {
                    theme: pdfPreviewRoot.theme
                    compact: true
                    text: "+"
                    onClicked: zoomPercent = clampZoom(zoomPercent + 10)
                }

                AppButton {
                    theme: pdfPreviewRoot.theme
                    text: i18n ? i18n.t("pdf.fitWidth") : "Fit Width"
                    onClicked: fitWidth()
                }

                Text {
                    text: pageCountText()
                    color: themeSubText
                    font.pixelSize: 12
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 0
            color: "transparent"
            border.width: 0
            border.color: "transparent"

            ScrollView {
                id: previewScroll
                anchors.fill: parent
                anchors.margins: 0
                clip: true
                contentWidth: previewContent.width
                contentHeight: previewContent.height
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                background: Rectangle {
                    color: "transparent"
                    border.width: 0
                    border.color: "transparent"
                }

                Item {
                    id: previewContent
                    width: Math.max(previewScroll.availableWidth, calculatedPageWidth + pageHorizontalPadding * 2)
                    height: Math.max(
                        previewScroll.availableHeight,
                        hasRenderedPages
                            ? pagesColumn.implicitHeight + pageTopPadding * 2
                            : placeholderPageHeight + pageTopPadding * 2
                    )

                    Column {
                        id: pagesColumn
                        visible: hasRenderedPages
                        width: parent.width
                        spacing: pageSpacing
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: pageTopPadding

                        Repeater {
                            model: displayPreviewImagePaths

                            delegate: Item {
                                id: renderedPage

                                required property string modelData
                                property real pageRatio: pageImage.sourceSize.width > 0 && pageImage.sourceSize.height > 0
                                    ? pageImage.sourceSize.height / pageImage.sourceSize.width
                                    : a4Ratio

                                width: pagesColumn.width
                                height: pageImage.height

                                Image {
                                    id: pageImage
                                    source: renderedPage.modelData
                                    width: calculatedPageWidth
                                    height: width * renderedPage.pageRatio
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: false
                                    cache: false
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: !hasRenderedPages
                        width: calculatedPageWidth
                        height: placeholderPageHeight
                        radius: 10
                        color: "#F8FBFF"
                        border.width: 1
                        border.color: themeBorder
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: pageTopPadding

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Math.max(22, calculatedPageWidth * 0.07)
                            spacing: Math.max(10, calculatedPageWidth * 0.025)

                            Text {
                                Layout.fillWidth: true
                                text: i18n ? i18n.t("pdf.welcomeTitle") : "Welcome to LumiTeX"
                                color: "#18263B"
                                font.pixelSize: Math.max(14, calculatedPageWidth * 0.034)
                                font.weight: Font.Bold
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: i18n ? i18n.t("pdf.welcomeSubtitle") : "Open or create a LaTeX project, then compile to preview the PDF here."
                                color: "#5A6C82"
                                font.pixelSize: Math.max(10, calculatedPageWidth * 0.024)
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: "#D7E1ED"
                            }

                            Text {
                                text: i18n ? i18n.t("pdf.welcomeStepTitle") : "Get started"
                                color: "#18263B"
                                font.pixelSize: Math.max(11, calculatedPageWidth * 0.026)
                                font.weight: Font.Bold
                            }

                            Text {
                                Layout.fillWidth: true
                                text: i18n ? i18n.t("pdf.welcomeStepOne") : "Create a new project or open an existing LaTeX folder."
                                color: "#33455C"
                                font.pixelSize: Math.max(9, calculatedPageWidth * 0.021)
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                text: i18n ? i18n.t("pdf.welcomeCompileTitle") : "Preview"
                                color: "#18263B"
                                font.pixelSize: Math.max(11, calculatedPageWidth * 0.026)
                                font.weight: Font.Bold
                            }

                            Text {
                                Layout.fillWidth: true
                                text: i18n ? i18n.t("pdf.welcomeStepTwo") : "Compile your document and the generated PDF will appear here."
                                color: "#33455C"
                                font.pixelSize: Math.max(9, calculatedPageWidth * 0.021)
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }

            Text {
                visible: !hasRenderedPages
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 20
                text: i18n ? i18n.t("pdf.compileToRender") : "Compile to render the real PDF preview"
                color: themeSubText
                font.pixelSize: 12
            }
        }
    }
}
