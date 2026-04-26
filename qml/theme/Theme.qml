import QtQuick

QtObject {
    property bool darkMode: true

    readonly property color background: darkMode ? "#08111F" : "#F4F7FB"
    readonly property color panel: darkMode ? "#0D1728" : "#FFFFFF"
    readonly property color card: darkMode ? "#13233D" : "#EEF3F8"
    readonly property color border: darkMode ? "#213553" : "#D7E1EC"
    readonly property color text: darkMode ? "#F3F7FF" : "#142033"
    readonly property color subText: darkMode ? "#8EA3C2" : "#65758B"
    readonly property color accent: darkMode ? "#5BA8FF" : "#2563EB"
    readonly property color success: darkMode ? "#3DD598" : "#168A5B"
    readonly property color warning: darkMode ? "#FFBE5C" : "#B7791F"
    readonly property color error: darkMode ? "#FF6B6B" : "#D64545"
    readonly property color editorBackground: darkMode ? "#101C31" : "#F8FBFF"
    readonly property color pdfBackground: darkMode ? "#101C31" : "#E9EEF5"

    readonly property color panelSoft: darkMode ? "#0C1627" : "#F8FAFD"
    readonly property color hover: darkMode ? "#182842" : "#E8F0FA"
    readonly property color lineHighlight: darkMode ? "#15243A" : "#EAF2FD"

    readonly property int cardRadius: 18
    readonly property int buttonRadius: 12
    readonly property int panelPadding: 18
    readonly property int smallFontSize: 11
    readonly property int normalFontSize: 13
    readonly property int titleFontSize: 18
}
