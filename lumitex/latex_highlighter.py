from PySide6.QtCore import QObject, QRegularExpression, Slot
from PySide6.QtGui import QColor, QSyntaxHighlighter, QTextCharFormat
from PySide6.QtQuick import QQuickTextDocument


class LatexSyntaxHighlighter(QSyntaxHighlighter):
    def __init__(self, document, dark_mode: bool = True) -> None:
        super().__init__(document)
        self.dark_mode = dark_mode
        self._configure_formats()

    def set_dark_mode(self, dark_mode: bool) -> None:
        if self.dark_mode == dark_mode:
            return
        self.dark_mode = dark_mode
        self._configure_formats()
        self.rehighlight()

    def _configure_formats(self) -> None:
        if self.dark_mode:
            colors = {
                "command": "#67D8EF",
                "comment": "#6A9955",
                "math": "#C586F7",
                "environment": "#7EE787",
                "brace": "#FFD166",
                "optional": "#A7C7FF",
                "key": "#8CC7FF",
            }
        else:
            colors = {
                "command": "#005CC5",
                "comment": "#2E7D32",
                "math": "#8A3FFC",
                "environment": "#168A5B",
                "brace": "#9A6700",
                "optional": "#315DA8",
                "key": "#0969DA",
            }

        self.command_format = self._format(colors["command"], bold=True)
        self.comment_format = self._format(colors["comment"])
        self.math_format = self._format(colors["math"])
        self.environment_format = self._format(colors["environment"], bold=True)
        self.brace_format = self._format(colors["brace"])
        self.optional_format = self._format(colors["optional"])
        self.key_format = self._format(colors["key"])

    def _format(self, color: str, bold: bool = False) -> QTextCharFormat:
        text_format = QTextCharFormat()
        text_format.setForeground(QColor(color))
        if bold:
            text_format.setFontWeight(600)
        return text_format

    def highlightBlock(self, text: str) -> None:
        self._apply_regex(QRegularExpression(r"\$[^$\n]*\$"), text, self.math_format)
        self._apply_regex(QRegularExpression(r"\\\[[^\n]*\\\]"), text, self.math_format)
        self._apply_regex(QRegularExpression(r"\\\([^\n]*\\\)"), text, self.math_format)
        self._apply_regex(QRegularExpression(r"\[[^\]\n]*\]"), text, self.optional_format)
        self._apply_regex(QRegularExpression(r"\\[A-Za-z@]+|\\."), text, self.command_format)
        self._apply_regex(QRegularExpression(r"[{}]"), text, self.brace_format)
        self._apply_captured_regex(
            QRegularExpression(r"\\(?:begin|end)\s*\{(equation|figure|table|itemize|enumerate|abstract)\}"),
            text,
            self.environment_format,
            1,
        )
        self._apply_captured_regex(
            QRegularExpression(r"\\(?:cite|ref|label)\*?(?:\[[^\]\n]*\])?\{([^}\n]*)\}"),
            text,
            self.key_format,
            1,
        )

        comment_start = self._comment_start(text)
        if comment_start >= 0:
            self.setFormat(comment_start, len(text) - comment_start, self.comment_format)

    def _apply_regex(self, expression: QRegularExpression, text: str, text_format: QTextCharFormat) -> None:
        match_iterator = expression.globalMatch(text)
        while match_iterator.hasNext():
            match = match_iterator.next()
            self.setFormat(match.capturedStart(), match.capturedLength(), text_format)

    def _apply_captured_regex(
        self,
        expression: QRegularExpression,
        text: str,
        text_format: QTextCharFormat,
        group: int,
    ) -> None:
        match_iterator = expression.globalMatch(text)
        while match_iterator.hasNext():
            match = match_iterator.next()
            start = match.capturedStart(group)
            length = match.capturedLength(group)
            if start >= 0 and length > 0:
                self.setFormat(start, length, text_format)

    def _comment_start(self, text: str) -> int:
        index = 0
        while index < len(text):
            percent_index = text.find("%", index)
            if percent_index < 0:
                return -1
            slash_count = 0
            cursor = percent_index - 1
            while cursor >= 0 and text[cursor] == "\\":
                slash_count += 1
                cursor -= 1
            if slash_count % 2 == 0:
                return percent_index
            index = percent_index + 1
        return -1

class LatexHighlighterBridge(QObject):
    def __init__(self) -> None:
        super().__init__()
        self._highlighter: LatexSyntaxHighlighter | None = None
        self._dark_mode = True

    @Slot(QObject)
    def attach(self, text_document: QObject) -> None:
        if not isinstance(text_document, QQuickTextDocument):
            return

        document = text_document.textDocument()
        if not document:
            return

        if self._highlighter and self._highlighter.document() is document:
            self._highlighter.set_dark_mode(self._dark_mode)
            return

        self._highlighter = LatexSyntaxHighlighter(document, self._dark_mode)

    @Slot()
    def detach(self) -> None:
        if self._highlighter:
            self._highlighter.setDocument(None)
            self._highlighter = None

    @Slot(bool)
    def setDarkMode(self, dark_mode: bool) -> None:
        self._dark_mode = dark_mode
        if self._highlighter:
            self._highlighter.set_dark_mode(dark_mode)
