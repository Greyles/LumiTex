import QtQuick
import QtQuick.Controls

Button {
    id: control

    property var theme: null
    property bool compact: false
    property bool active: false

    implicitHeight: 30
    implicitWidth: compact ? 32 : Math.max(76, contentItem.implicitWidth + leftPadding + rightPadding)
    leftPadding: compact ? 0 : 12
    rightPadding: compact ? 0 : 12
    topPadding: 0
    bottomPadding: 0
    hoverEnabled: true

    contentItem: Text {
        text: control.text
        color: control.enabled ? (control.theme ? control.theme.text : "#F3F7FF")
                               : (control.theme ? control.theme.subText : "#8EA3C2")
        opacity: control.enabled ? 1.0 : 0.55
        font.pixelSize: control.theme ? control.theme.normalFontSize : 13
        font.weight: control.active ? Font.DemiBold : Font.Medium
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: control.theme ? control.theme.buttonRadius : 10
        color: {
            if (!control.enabled) {
                return control.theme ? control.theme.panelSoft : "#0C1627"
            }
            if (control.down) {
                return control.theme && control.theme.darkMode ? "#213553" : "#DDE8F5"
            }
            if (control.active) {
                return control.theme && control.theme.darkMode ? "#1A3456" : "#DCEBFF"
            }
            if (control.hovered) {
                return control.theme ? control.theme.hover : "#182842"
            }
            return control.theme ? control.theme.panelSoft : "#0C1627"
        }
        border.width: 1
        border.color: control.active
                      ? (control.theme ? control.theme.accent : "#5BA8FF")
                      : (control.theme ? control.theme.border : "#213553")
        opacity: control.enabled ? 1.0 : 0.65
    }
}
