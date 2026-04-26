from pathlib import Path

from PySide6.QtCore import QObject, QProcess, QStandardPaths, Signal


class LatexCompiler(QObject):
    started = Signal()
    finished = Signal(bool, str, str)
    VALID_ENGINES = {"xelatex", "pdflatex", "latexmk"}

    def __init__(self, project_dir: Path, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self.project_dir = Path(project_dir)
        self.current_tex_path = self.project_dir / "main.tex"
        self.engine = "xelatex"
        self._process: QProcess | None = None
        self._log_parts: list[str] = []
        self._commands: list[tuple[str, list[str]]] = []
        self._command_index = 0
        self.last_result: dict[str, object] = {}

    def command_preview(self, tex_name: str = "main.tex") -> str:
        engine = self._normalized_engine()
        if engine == "latexmk":
            return f"latexmk -pdf -interaction=nonstopmode -file-line-error {tex_name}"
        return f"{engine} -interaction=nonstopmode -file-line-error {tex_name}"

    def compile(self, tex_path: Path | str | None = None) -> None:
        if self._process and self._process.state() != QProcess.ProcessState.NotRunning:
            self.finished.emit(False, "Compile failed.", "A LaTeX compile process is already running.")
            return

        engine = self._normalized_engine()
        tex_file = Path(tex_path) if tex_path else self.project_dir / "main.tex"
        tex_file = tex_file.resolve()
        if not tex_file.exists():
            self.finished.emit(False, "Compile failed.", f"Missing tex file: {tex_file}")
            return

        try:
            tex_argument = tex_file.relative_to(self.project_dir.resolve()).as_posix()
        except ValueError:
            tex_argument = tex_file.name
        try:
            output_directory = tex_file.parent.relative_to(self.project_dir.resolve()).as_posix()
        except ValueError:
            output_directory = tex_file.parent.as_posix()
        output_argument = output_directory if output_directory != "." else "."

        self.current_tex_path = tex_file
        self._log_parts = []
        self._command_index = 0
        self._commands = self._build_commands(engine, tex_argument, output_argument)
        self.last_result = {
            "success": False,
            "engine": engine,
            "commands": [self._format_command(program, args) for program, args in self._commands],
            "log": "",
            "pdf_path": str(self.current_tex_path.with_suffix(".pdf")),
        }

        for program, _args in self._commands:
            if not QStandardPaths.findExecutable(program):
                message = f"{program} not found. Please install TeX Live or MiKTeX and make sure {program} is in PATH."
                self.last_result["log"] = message
                self.finished.emit(False, "Compile failed.", message)
                return

        print("Current compiler engine:", engine)
        self.started.emit()
        self._start_next_command()

    def _normalized_engine(self) -> str:
        return self.engine if self.engine in self.VALID_ENGINES else "xelatex"

    def _build_commands(self, engine: str, tex_argument: str, output_argument: str) -> list[tuple[str, list[str]]]:
        tex_base = Path(tex_argument).with_suffix("").as_posix()
        if engine == "latexmk":
            return [(
                "latexmk",
                [
                    "-pdf",
                    "-interaction=nonstopmode",
                    "-file-line-error",
                    f"-output-directory={output_argument}",
                    tex_argument,
                ],
            )]

        latex_args = [
            "-interaction=nonstopmode",
            "-file-line-error",
            f"-output-directory={output_argument}",
            tex_argument,
        ]
        return [
            (engine, latex_args),
            ("bibtex", [tex_base]),
            (engine, latex_args),
            (engine, latex_args),
        ]

    def _start_next_command(self) -> None:
        if self._command_index >= len(self._commands):
            self._finish_sequence()
            return

        program, args = self._commands[self._command_index]
        command_text = self._format_command(program, args)
        print("Running command:", command_text)
        self._log_parts.append(f"\n$ {command_text}\n")

        self._process = QProcess(self)
        self._process.setProgram(program)
        self._process.setArguments(args)
        self._process.setWorkingDirectory(str(self.project_dir.resolve()))
        self._process.setProcessChannelMode(QProcess.ProcessChannelMode.MergedChannels)
        self._process.readyReadStandardOutput.connect(self._read_stdout)
        self._process.errorOccurred.connect(self._handle_error)
        self._process.finished.connect(self._handle_command_finished)
        self._process.start()

    def _format_command(self, program: str, args: list[str]) -> str:
        return " ".join([program] + args)

    def _read_stdout(self) -> None:
        if not self._process:
            return
        self._append_log(self._process.readAllStandardOutput())

    def _append_log(self, data: bytes) -> None:
        if data:
            self._log_parts.append(bytes(data).decode("utf-8", errors="replace"))

    def _handle_error(self, error: QProcess.ProcessError) -> None:
        if error == QProcess.ProcessError.FailedToStart:
            program = self._commands[self._command_index][0] if self._commands else self._normalized_engine()
            message = f"{program} not found. Please install TeX Live or MiKTeX and make sure {program} is in PATH."
            self.last_result["log"] = message
            self.finished.emit(False, "Compile failed.", message)

    def _handle_command_finished(self, exit_code: int, exit_status: QProcess.ExitStatus) -> None:
        if not self._process:
            return

        self._read_stdout()
        program, args = self._commands[self._command_index]
        command_text = self._format_command(program, args)
        if exit_status != QProcess.ExitStatus.NormalExit or exit_code != 0:
            if program == "bibtex":
                self._log_parts.append(
                    f"\nBibTeX exited with code {exit_code}; continuing LaTeX passes for documents without bibliography data.\n"
                )
                self._command_index += 1
                self._process = None
                self._start_next_command()
                return

            log_text = "".join(self._log_parts).strip()
            self.last_result.update({
                "success": False,
                "log": log_text,
            })
            self.finished.emit(False, "Compile failed.", log_text)
            return

        self._command_index += 1
        self._process = None
        self._start_next_command()

    def _finish_sequence(self) -> None:
        log_text = "".join(self._log_parts).strip()
        pdf_path = self.current_tex_path.with_suffix(".pdf")
        success = pdf_path.exists()
        message = "Compile succeeded. PDF generated." if success else "Compile failed."
        self.last_result.update({
            "success": success,
            "engine": self._normalized_engine(),
            "commands": [self._format_command(program, args) for program, args in self._commands],
            "log": log_text,
            "pdf_path": str(pdf_path),
        })
        self.finished.emit(success, message, log_text)
