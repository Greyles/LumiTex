import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: imagePreviewRoot

    property var theme: null
    property var i18n: null
    property string imageUrl: ""
    property string fileName: ""
    property real zoomScale: 1.0
    property bool fitWindow: true

    property color themePanel: theme ? theme.panel : "#0D1728"
    property color themePanelSoft: theme ? theme.panelSoft : "#0C1627"
    property color themeCard: theme ? theme.card : "#13233D"
    property color themeBorder: theme ? theme.border : "#17263D"
    property color themeText: theme ? theme.text : "#F3F7FF"
    property color themeSubText: theme ? theme.subText : "#8EA3C2"
    property color themeEditorBackground: theme ? theme.editorBackground : "#101C31"
    property int themeCardRadius: theme ? theme.cardRadius : 18
    property int themeButtonRadius: theme ? theme.buttonRadius : 12
    property int themeSmallFontSize: theme ? theme.smallFontSize : 11

    function trText(key, fallbackText) {
        return i18n ? i18n.t(key) : fallbackText
    }

    function zoomIn() {
        fitWindow = false
        zoomScale = Math.min(4.0, zoomScale + 0.15)
    }

    function zoomOut() {
        fitWindow = false
        zoomScale = Math.max(0.15, zoomScale - 0.15)
    }

    function fitToWindow() {
        fitWindow = true
        zoomScale = 1.0
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
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: fileName.length > 0 ? fileName : trText("image.preview", "Image Preview")
                    color: themeText
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.preferredWidth: 112
                    Layout.preferredHeight: 24
                    radius: themeButtonRadius
                    color: theme && theme.darkMode ? "#12261E" : "#E8F7EF"

                    Text {
                        anchors.centerIn: parent
                        text: trText("image.preview", "Image Preview")
                        color: theme ? theme.success : "#3DD598"
                        font.pixelSize: themeSmallFontSize
                        font.weight: Font.DemiBold
                    }
                }

                AppButton {
                    theme: imagePreviewRoot.theme
                    text: "-"
                    onClicked: imagePreviewRoot.zoomOut()
                }

                Text {
                    Layout.preferredWidth: 62
                    text: fitWindow ? trText("pdf.fit", "Fit") : Math.round(zoomScale * 100) + "%"
                    color: themeSubText
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                AppButton {
                    theme: imagePreviewRoot.theme
                    text: "+"
                    onClicked: imagePreviewRoot.zoomIn()
                }

                AppButton {
                    theme: imagePreviewRoot.theme
                    text: trText("image.fitWindow", "Fit Window")
                    onClicked: imagePreviewRoot.fitToWindow()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: themeCardRadius
            color: themeEditorBackground
            border.width: 1
            border.color: themeBorder
            clip: true

            ScrollView {
                id: previewScroll

                readonly property real imageAspect: previewImage.status === Image.Ready && previewImage.sourceSize.width > 0
                    ? previewImage.sourceSize.height / previewImage.sourceSize.width
                    : 0.75
                readonly property real naturalWidth: previewImage.status === Image.Ready && previewImage.sourceSize.width > 0
                    ? previewImage.sourceSize.width
                    : 640
                readonly property real fitWidth: Math.max(160, availableWidth - 48)
                readonly property real fitHeightWidth: Math.max(160, (availableHeight - 48) / imageAspect)
                readonly property real displayedWidth: fitWindow
                    ? Math.min(fitWidth, fitHeightWidth)
                    : Math.max(80, naturalWidth * zoomScale)
                readonly property real displayedHeight: displayedWidth * imageAspect

                anchors.fill: parent
                clip: true
                contentWidth: Math.max(availableWidth, displayedWidth + 48)
                contentHeight: Math.max(availableHeight, displayedHeight + 48)
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ScrollBar.horizontal.policy: ScrollBar.AsNeeded

                Item {
                    width: previewScroll.contentWidth
                    height: previewScroll.contentHeight

                    Image {
                        id: previewImage

                        source: imagePreviewRoot.imageUrl
                        width: previewScroll.displayedWidth
                        height: previewScroll.displayedHeight
                        x: Math.max(24, (parent.width - width) / 2)
                        y: Math.max(24, (parent.height - height) / 2)
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: false
                        smooth: true
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: imagePreviewRoot.imageUrl.length === 0 || previewImage.status === Image.Error
                        text: trText("image.loadFailed", "Failed to load image.")
                        color: themeSubText
                        font.pixelSize: 13
                    }
                }
            }
        }
    }
}
