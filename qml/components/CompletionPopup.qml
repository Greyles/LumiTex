import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: completionPopup

    property var theme: null
    property var i18n: null
    property var suggestions: []
    property int selectedIndex: 0

    signal completionAccepted(var item)

    function moveSelection(delta) {
        if (suggestions.length === 0) {
            selectedIndex = 0
            return
        }
        selectedIndex = (selectedIndex + delta + suggestions.length) % suggestions.length
        completionList.currentIndex = selectedIndex
    }

    function acceptCurrent() {
        if (suggestions.length === 0) {
            return
        }
        completionAccepted(suggestions[Math.max(0, Math.min(selectedIndex, suggestions.length - 1))])
    }

    function descriptionFor(item) {
        if (i18n && i18n.currentLanguage === "zh" && item.descriptionZh) {
            return item.descriptionZh
        }
        return item.description || ""
    }

    onSuggestionsChanged: selectedIndex = 0

    width: 320
    height: visible ? Math.min(286, Math.max(46, suggestions.length * 44 + 10)) : 0
    visible: suggestions.length > 0
    radius: theme ? theme.cardRadius : 14
    color: theme ? theme.panel : "#0D1728"
    border.width: 1
    border.color: theme ? theme.border : "#213553"
    clip: true

    ListView {
        id: completionList

        anchors.fill: parent
        anchors.margins: 5
        clip: true
        model: completionPopup.suggestions
        currentIndex: completionPopup.selectedIndex
        boundsBehavior: Flickable.StopAtBounds

        delegate: Rectangle {
            id: completionRow

            required property var modelData
            required property int index

            width: completionList.width
            height: 44
            radius: 8
            color: index === completionPopup.selectedIndex
                ? (completionPopup.theme ? completionPopup.theme.hover : "#182842")
                : (rowMouse.containsMouse ? (completionPopup.theme ? completionPopup.theme.panelSoft : "#0C1627") : "transparent")

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: completionRow.modelData.command || ""
                    color: completionPopup.theme ? completionPopup.theme.text : "#F3F7FF"
                    font.family: Qt.platform.os === "windows" ? "Consolas" : "Monospace"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: completionPopup.descriptionFor(completionRow.modelData)
                    color: completionPopup.theme ? completionPopup.theme.subText : "#8EA3C2"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            MouseArea {
                id: rowMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: completionPopup.selectedIndex = completionRow.index
                onClicked: completionPopup.completionAccepted(completionRow.modelData)
            }
        }
    }
}
