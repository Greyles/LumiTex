import sys
from pathlib import Path


from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle

from lumitex.app_bridge import AppBridge
from lumitex.latex_highlighter import LatexHighlighterBridge


def main():
    QQuickStyle.setStyle("Basic")

    app = QGuiApplication(sys.argv)
    app.setApplicationName("LumiTeX")
    app.setOrganizationName("LumiTeX")
    app.setApplicationDisplayName("LumiTeX")

    app_bridge = AppBridge()
    latex_highlighter = LatexHighlighterBridge()

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("appBridge", app_bridge)
    engine.rootContext().setContextProperty("latexHighlighter", latex_highlighter)
    qml_path = Path(__file__).resolve().parent / "qml" / "Main.qml"
    engine.load(QUrl.fromLocalFile(str(qml_path)))

    if not engine.rootObjects():
        return -1

    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
