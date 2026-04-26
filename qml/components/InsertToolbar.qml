import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    property var theme: null
    property var i18n: null

    signal insertRequested(string snippet, string mode)

    property color themePanelSoft: theme ? theme.panelSoft : "#0C1627"
    property color themeBorder: theme ? theme.border : "#17263D"
    property color themeText: theme ? theme.text : "#F3F7FF"
    property color themeAccent: theme ? theme.accent : "#5BA8FF"
    property color themeHover: theme ? theme.hover : "#182842"
    property int themeButtonRadius: theme ? theme.buttonRadius : 12
    property int themeSmallFontSize: theme ? theme.smallFontSize : 11

    implicitHeight: 42
    radius: themeButtonRadius
    color: themePanelSoft
    border.width: 1
    border.color: themeBorder

    component InsertButton: Button {
        id: insertButton

        required property string snippet
        property string mode: "insert"

        implicitHeight: 28
        leftPadding: 10
        rightPadding: 10
        hoverEnabled: true

        background: Rectangle {
            radius: themeButtonRadius
            color: insertButton.down ? themeAccent : (insertButton.hovered ? themeHover : "transparent")
            border.width: 1
            border.color: insertButton.hovered || insertButton.down ? themeAccent : themeBorder
        }

        contentItem: Text {
            text: insertButton.text
            color: insertButton.down ? (theme && theme.darkMode ? "#08111F" : "#FFFFFF") : themeText
            font.pixelSize: themeSmallFontSize
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        onClicked: insertRequested(snippet, mode)
    }

    ScrollView {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        clip: true

        RowLayout {
            spacing: 8

            InsertButton {
                text: i18n ? i18n.t("editor.section") : "Section"
                mode: "section"
                snippet: "\\section{Title}\n"
            }
            InsertButton {
                text: i18n ? i18n.t("editor.subsection") : "Subsection"
                mode: "subsection"
                snippet: "\\subsection{Title}\n"
            }
            InsertButton {
                text: i18n ? i18n.t("editor.equation") : "Equation"
                snippet: "\\begin{equation}\n    \n\\end{equation}\n"
            }
            InsertButton {
                text: i18n ? i18n.t("editor.figure") : "Figure"
                mode: "figure"
                snippet: "\\begin{figure}[htbp]\n    \\centering\n    \\includegraphics[width=0.8\\linewidth]{figures/example.png}\n    \\caption{Figure caption.}\n    \\label{fig:example}\n\\end{figure}\n"
            }
            InsertButton {
                text: i18n ? i18n.t("editor.table") : "Table"
                snippet: "\\begin{table}[htbp]\n    \\centering\n    \\caption{Table caption.}\n    \\label{tab:example}\n    \\begin{tabular}{c c}\n        \\hline\n        Column 1 & Column 2 \\\\\n        \\hline\n        A & B \\\\\n        \\hline\n    \\end{tabular}\n\\end{table}\n"
            }
            InsertButton {
                text: i18n ? i18n.t("editor.cite") : "Cite"
                snippet: "\\cite{reference_key}"
            }
            InsertButton {
                text: i18n ? i18n.t("editor.ref") : "Ref"
                snippet: "\\ref{label_key}"
            }
            InsertButton {
                text: i18n ? i18n.t("editor.itemize") : "Itemize"
                snippet: "\\begin{itemize}\n    \\item First item\n    \\item Second item\n\\end{itemize}\n"
            }
        }
    }
}
