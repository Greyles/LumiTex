from pathlib import Path
import threading

from PySide6.QtCore import Property, QObject, QUrl, Signal, Slot
from PySide6.QtGui import QGuiApplication

from lumitex.cleaner import LatexCleaner
from lumitex.compiler import LatexCompiler
from lumitex.file_manager import import_image_to_project, read_text_file, write_text_file
from lumitex.log_parser import LogParser
from lumitex.pdf_renderer import PdfRenderer
from lumitex.project_manager import IMAGE_PREVIEW_EXTENSIONS, ProjectManager, TEXT_OPENABLE_EXTENSIONS
from lumitex.settings_manager import SettingsManager
from lumitex.template_manager import TemplateManager


DEFAULT_MAIN_TEX = r"""\documentclass[11pt]{article}

\usepackage[a4paper,margin=1in]{geometry}
\usepackage{fontspec}
\usepackage{graphicx}

\title{LumiTeX Demo Paper}
\author{LumiTeX}
\date{\today}

\begin{document}

\maketitle

\begin{abstract}
This is a minimal demo paper used to verify editing, saving, compiling, and PDF
preview rendering in LumiTeX.
\end{abstract}

\section{Introduction}
LumiTeX is a lightweight, modern, local-first LaTeX writing workspace for
students and researchers.

\section{Conclusion}
Edit this document, save it, then compile to refresh the PDF preview.

\end{document}
"""


class AppBridge(QObject):
    compileStarted = Signal()
    compileFinished = Signal(bool, str, str)
    previewUpdated = Signal(str)
    previewPagesUpdated = Signal(list)
    previewFailed = Signal(str)
    fileStatusChanged = Signal(bool, str, str)
    currentProjectChanged = Signal()
    projectTreeChanged = Signal(list)
    projectFilesChanged = Signal()
    openFilesChanged = Signal()
    currentFileChanged = Signal(str)
    fileOpened = Signal(str)
    currentFileLoaded = Signal(str, str)
    loadFileStarted = Signal(str)
    textFileReadFinished = Signal(int, str, str, str)
    imageFileLoaded = Signal(str, str)
    currentFileTypeChanged = Signal()
    problemsUpdated = Signal(list)
    settingsChanged = Signal(dict)
    languageChanged = Signal(str)
    statusMessageChanged = Signal()
    compileLogChanged = Signal()
    previewImagePathChanged = Signal()
    previewImagePathsChanged = Signal()
    projectNameChanged = Signal()
    currentFileNameChanged = Signal()
    projectClosed = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._status_message = "No project opened."
        self._compile_log = ""
        self._preview_image_path = ""
        self._preview_image_paths: list[str] = []
        self._problems: list[dict[str, str | int]] = []
        app_root = Path(__file__).resolve().parent.parent
        templates_dir = Path(__file__).resolve().parent.parent / "templates"
        settings_path = Path(__file__).resolve().parent.parent / "lumitex_settings.json"
        self._project_manager = ProjectManager()
        self._template_manager = TemplateManager(templates_dir)
        self._settings_manager = SettingsManager(settings_path)
        self._settings = self._settings_manager.load_settings()
        self._current_file_relative_path = ""
        self._current_file_type = ""
        self._current_main_tex_path = Path()
        self._current_compile_tex_relative_path = ""
        self._open_files: list[str] = []
        self._modified_files: set[str] = set()
        self._open_file_contents: dict[str, str] = {}
        self._load_request_id = 0
        self._compiler = LatexCompiler(app_root, self)
        self._cleaner = LatexCleaner()
        self._compiler.engine = self._current_compiler_engine()
        self._pdf_renderer = PdfRenderer()
        self._log_parser = LogParser()
        self.textFileReadFinished.connect(self._finish_text_file_load)
        self._compiler.started.connect(self._handle_compile_started)
        self._compiler.finished.connect(self._handle_compile_finished)

    def get_status_message(self) -> str:
        return self._status_message

    def get_compile_log(self) -> str:
        return self._compile_log

    def get_preview_image_path(self) -> str:
        return self._preview_image_path

    def get_preview_image_paths(self) -> list[str]:
        return self._preview_image_paths

    def get_problems(self) -> list[dict[str, str | int]]:
        return self._problems

    def get_project_files(self) -> list[dict[str, str | bool | int]]:
        return self._project_manager.get_project_files()

    @Slot(result="QVariantList")
    def get_project_tree(self) -> list[dict[str, object]]:
        tree = self._project_manager.get_project_tree()
        print("AppBridge get_project_tree:", tree)
        return tree

    @Slot(result="QVariantList")
    def get_open_files(self) -> list[dict[str, str | bool]]:
        open_files = [
            {
                "name": Path(relative_path).name,
                "path": relative_path,
                "relativePath": relative_path,
                "type": Path(relative_path).suffix.lower().lstrip("."),
                "modified": relative_path in self._modified_files,
                "active": relative_path == self._current_file_relative_path,
            }
            for relative_path in self._open_files
        ]
        print("AppBridge open files:", open_files)
        return open_files

    def get_project_name(self) -> str:
        project_dir = self._project_manager.get_project_dir()
        return Path(project_dir).name if project_dir else ""

    def get_current_file_name(self) -> str:
        return self._current_file_relative_path

    def get_current_file_type(self) -> str:
        return self._current_file_type

    def get_current_language(self) -> str:
        return "zh" if self._settings.get("language") == "zh" else "en"

    @Slot(result="QVariantMap")
    def load_settings(self) -> dict:
        self._settings = self._settings_manager.load_settings()
        self._compiler.engine = self._current_compiler_engine()
        print("Loaded settings:", self._settings)
        print("Loaded compiler:", self._compiler.engine)
        return self._settings

    @Slot("QVariant", result=bool)
    def save_settings(self, settings: dict) -> bool:
        previous_language = self.get_current_language()
        settings_dict = dict(settings)
        if "compiler" in settings_dict and "compilerEngine" not in settings_dict:
            settings_dict["compilerEngine"] = settings_dict["compiler"]
        if "compilerEngine" in settings_dict:
            settings_dict["compiler"] = settings_dict["compilerEngine"]
        print("Saving settings:", settings_dict)
        if not self._settings_manager.save_settings(settings_dict):
            self._set_file_status(False, "Failed to save settings.", "Could not write lumitex_settings.json.")
            return False

        self._settings = self._settings_manager.load_settings()
        self._compiler.engine = self._current_compiler_engine()
        print("Saved compiler:", self._compiler.engine)
        self.settingsChanged.emit(self._settings)
        current_language = self.get_current_language()
        if current_language != previous_language:
            self.languageChanged.emit(current_language)
        self._set_file_status(True, "Settings saved.", "Settings saved to lumitex_settings.json.")
        return True

    @Slot(str, result=bool)
    def copy_to_clipboard(self, text: str) -> bool:
        try:
            QGuiApplication.clipboard().setText(text)
            return True
        except RuntimeError:
            return False

    @Slot(result=bool)
    def clean_aux_files(self) -> bool:
        project_dir = self._project_manager.get_project_dir()
        if not project_dir:
            message = "Please open a project first."
            self._status_message = message
            self._compile_log = message
            self._problems = [{
                "type": "warning",
                "file": "",
                "line": -1,
                "message": message,
            }]
            self.statusMessageChanged.emit()
            self.compileLogChanged.emit()
            self.problemsUpdated.emit(self._problems)
            self.fileStatusChanged.emit(False, message, message)
            return False

        self._status_message = "Cleaning auxiliary files..."
        self._compile_log = project_dir
        self._problems = [{
            "type": "info",
            "file": "",
            "line": -1,
            "message": "Cleaning auxiliary files...",
        }]
        self.statusMessageChanged.emit()
        self.compileLogChanged.emit()
        self.problemsUpdated.emit(self._problems)

        result = self._cleaner.clean_aux_files(project_dir)
        deleted_files = result.get("deleted_files", [])
        if any(str(item).startswith(".lumitex_cache/") for item in deleted_files):
            self._preview_image_path = ""
            self._preview_image_paths = []
            self.previewImagePathChanged.emit()
            self.previewImagePathsChanged.emit()

        deleted_preview = "\n".join(str(item) for item in deleted_files[:10])
        if len(deleted_files) > 10:
            deleted_preview += f"\n... and {len(deleted_files) - 10} more"

        message = str(result.get("message", "Failed to clean auxiliary files."))
        log_text = deleted_preview if deleted_preview else message
        problem_type = "info" if result.get("success") else "error"
        self._status_message = message
        self._compile_log = log_text
        self._problems = [{
            "type": problem_type,
            "file": "",
            "line": -1,
            "message": message,
        }]
        self.statusMessageChanged.emit()
        self.compileLogChanged.emit()
        self.problemsUpdated.emit(self._problems)
        self.fileStatusChanged.emit(bool(result.get("success")), message, log_text)
        self.projectFilesChanged.emit()
        return bool(result.get("success"))

    @Slot(result="QVariantList")
    def list_templates(self) -> list[dict[str, str]]:
        return self._template_manager.list_templates()

    @Slot(str, str, str, result=bool)
    def create_project(self, template_id: str, target_dir: str, project_name: str) -> bool:
        target_path = self._path_from_qml(target_dir)
        result = self._template_manager.create_project_from_template(
            template_id,
            str(target_path),
            project_name,
        )
        if not result.get("success"):
            self._set_file_status(False, "Failed to create project.", result.get("message", "Unknown error."))
            return False

        project_dir = str(result["project_dir"])
        opened = self.open_project(project_dir)
        if opened:
            self._set_file_status(True, "Project created.", project_dir)
        return opened

    @Slot(result=str)
    def load_main_tex(self) -> str:
        if not self._project_manager.has_project():
            self._set_file_status(False, "No project opened.", "No project opened.")
            return ""

        main_file = self._project_manager.find_main_tex()
        if not main_file:
            self._set_file_status(False, "Main tex file not found.", self._project_manager.get_project_dir())
            return ""
        return self.load_file(main_file)

    @Slot(str, result=bool)
    def open_project(self, path: str) -> bool:
        project_path = self._path_from_qml(path)
        if not project_path.exists() or not project_path.is_dir():
            self._set_file_status(False, "Failed to open project.", str(project_path))
            return False

        self._project_manager.set_project_dir(str(project_path))
        self._current_file_relative_path = ""
        self._current_file_type = "text"
        self._current_main_tex_path = Path()
        self._current_compile_tex_relative_path = ""
        self._open_files = []
        self._modified_files = set()
        self._open_file_contents = {}
        self._preview_image_path = ""
        self._preview_image_paths = []
        self._compiler.project_dir = project_path
        self.projectNameChanged.emit()
        self.currentFileNameChanged.emit()
        self.currentFileTypeChanged.emit()
        self.currentFileChanged.emit("")
        self.projectTreeChanged.emit(self.get_project_tree())
        self.projectFilesChanged.emit()
        self.openFilesChanged.emit()
        self.previewImagePathChanged.emit()
        self.previewImagePathsChanged.emit()
        self.currentProjectChanged.emit()
        self._set_file_status(True, "Project opened.", str(project_path))

        main_file = self._project_manager.find_main_tex()
        if main_file:
            self.load_file(main_file)
        else:
            self._set_file_status(False, "Main tex file not found.", str(project_path))
        return True

    @Slot(result="QVariantMap")
    def close_project(self) -> dict:
        self._project_manager.clear_project()
        self._current_file_relative_path = ""
        self._current_file_type = ""
        self._current_main_tex_path = Path()
        self._current_compile_tex_relative_path = ""
        self._open_files = []
        self._modified_files = set()
        self._open_file_contents = {}
        self._preview_image_path = ""
        self._preview_image_paths = []
        self._problems = []
        self._status_message = "Project closed."
        self._compile_log = ""

        self.projectNameChanged.emit()
        self.currentFileNameChanged.emit()
        self.currentFileTypeChanged.emit()
        self.currentFileChanged.emit("")
        self.projectTreeChanged.emit([])
        self.projectFilesChanged.emit()
        self.openFilesChanged.emit()
        self.previewImagePathChanged.emit()
        self.previewImagePathsChanged.emit()
        self.problemsUpdated.emit([])
        self.statusMessageChanged.emit()
        self.compileLogChanged.emit()
        self.fileStatusChanged.emit(True, "Project closed.", "")
        self.projectClosed.emit()
        self.currentProjectChanged.emit()
        return {
            "success": True,
            "message": "Project closed.",
        }

    @Slot(str, result=str)
    def load_file(self, relative_path: str) -> str:
        file_path = self._resolve_project_file(relative_path)
        if not file_path:
            self._set_file_status(False, "Failed to load file.", relative_path)
            return ""

        normalized_path = Path(relative_path).as_posix()
        extension = file_path.suffix.lower()
        self._load_request_id += 1
        request_id = self._load_request_id
        self.loadFileStarted.emit(normalized_path)

        if extension in IMAGE_PREVIEW_EXTENSIONS:
            image_url = QUrl.fromLocalFile(str(file_path)).toString()
            self._current_file_relative_path = normalized_path
            self._current_file_type = "image"
            self._add_open_file(normalized_path)
            print("Loaded image preview:", self._current_file_relative_path, image_url)
            self.currentFileNameChanged.emit()
            self.currentFileTypeChanged.emit()
            self.currentFileChanged.emit(self._current_file_relative_path)
            self.openFilesChanged.emit()
            self.fileOpened.emit(self._current_file_relative_path)
            self._set_file_status(True, "File loaded.", image_url)
            self.imageFileLoaded.emit(self._current_file_relative_path, image_url)
            return image_url

        if extension not in TEXT_OPENABLE_EXTENSIONS:
            message = "This file type is not supported for preview yet."
            self._current_file_relative_path = normalized_path
            self._current_file_type = "unsupported"
            self._add_open_file(normalized_path)
            self.currentFileNameChanged.emit()
            self.currentFileTypeChanged.emit()
            self.currentFileChanged.emit(self._current_file_relative_path)
            self.openFilesChanged.emit()
            self._set_file_status(False, message, relative_path)
            self._set_warning_problem(message, relative_path)
            return ""

        self._current_file_relative_path = normalized_path
        self._current_file_type = "text"
        self._add_open_file(normalized_path)
        print("Loading current file:", self._current_file_relative_path)
        self.currentFileNameChanged.emit()
        self.currentFileTypeChanged.emit()
        self.currentFileChanged.emit(self._current_file_relative_path)
        self.openFilesChanged.emit()
        self.fileOpened.emit(self._current_file_relative_path)
        self._set_file_status(True, "Loading file...", f"Loading {file_path}")

        if normalized_path in self._open_file_contents:
            content = self._open_file_contents[normalized_path]
            self._finish_text_file_load(request_id, normalized_path, content, "")
            return content
        else:
            if file_path.stat().st_size > 1024 * 1024:
                self._set_warning_problem("This file is large and may load slowly.", normalized_path)
            thread = threading.Thread(
                target=self._read_text_file_worker,
                args=(request_id, normalized_path, str(file_path)),
                daemon=True,
            )
            thread.start()
        return ""

    def _read_text_file_worker(self, request_id: int, normalized_path: str, file_path: str) -> None:
        try:
            content = read_text_file(file_path)
            error = ""
        except OSError as exc:
            content = ""
            error = str(exc)
        self.textFileReadFinished.emit(request_id, normalized_path, content, error)

    @Slot(int, str, str, str)
    def _finish_text_file_load(self, request_id: int, normalized_path: str, content: str, error: str) -> None:
        if request_id != self._load_request_id or normalized_path != self._current_file_relative_path:
            return
        if error:
            self._set_file_status(False, "Failed to load file.", error)
            return

        self._open_file_contents[normalized_path] = content
        print("Loaded current file:", normalized_path)
        self._set_file_status(True, "File loaded.", f"Loaded {normalized_path}")
        self.currentFileLoaded.emit(normalized_path, content)

    @Slot(str, result="QVariantMap")
    def import_image(self, image_path: str) -> dict:
        if not self._project_manager.has_project():
            result = {
                "success": False,
                "message": "No project opened.",
            }
            self._set_file_status(False, result["message"], result["message"])
            return result

        source_path = self._path_from_qml(image_path)
        result = import_image_to_project(self._project_manager.get_project_dir(), source_path)
        message = str(result.get("message", "Failed to import image."))
        if result.get("success"):
            self.projectTreeChanged.emit(self.get_project_tree())
            self.projectFilesChanged.emit()
            self._set_file_status(True, message, str(result.get("relative_path", "")))
        else:
            self._set_file_status(False, message, str(source_path))
        return result

    @Slot(str)
    def report_warning(self, message: str) -> None:
        self._set_file_status(False, message, message)
        self._set_warning_problem(message, "")

    @Slot(str, str, bool)
    def update_open_file_content(self, relative_path: str, content: str, modified: bool) -> None:
        normalized_path = Path(relative_path).as_posix()
        if not normalized_path:
            return

        self._open_file_contents[normalized_path] = content
        self._add_open_file(normalized_path)
        if modified:
            self._modified_files.add(normalized_path)
        else:
            self._modified_files.discard(normalized_path)
        self.openFilesChanged.emit()

    @Slot(str, result=bool)
    def save_main_tex(self, content: str) -> bool:
        return self.save_current_file(content)

    @Slot(str, result=bool)
    def save_current_file(self, content: str) -> bool:
        return self._save_current_file(content, emit_status=True)

    @Slot(str)
    def compile_project(self, content: str) -> None:
        if not self._project_manager.has_project():
            message = "Please open or create a project first."
            self._status_message = message
            self._compile_log = message
            self._problems = [{
                "type": "error",
                "file": "",
                "line": -1,
                "message": message,
            }]
            self.statusMessageChanged.emit()
            self.compileLogChanged.emit()
            self.problemsUpdated.emit(self._problems)
            self.compileFinished.emit(False, message, self._compile_log)
            self.fileStatusChanged.emit(False, message, self._compile_log)
            return

        if (
            self._current_file_type == "text"
            and self._current_file_relative_path
            and not self._save_current_file(content, emit_status=False)
        ):
            message = "Compile failed."
            log_text = f"Failed to save {self._current_file_relative_path} before compiling."
            self._status_message = message
            self._compile_log = log_text
            self.statusMessageChanged.emit()
            self.compileLogChanged.emit()
            self.compileFinished.emit(False, message, log_text)
            return

        tex_file = self._select_compile_tex_file()
        if not tex_file:
            self._status_message = "No TeX file found to compile."
            self._compile_log = self._project_manager.get_project_dir()
            self.statusMessageChanged.emit()
            self.compileLogChanged.emit()
            self.compileFinished.emit(False, "No TeX file found to compile.", self._compile_log)
            return

        tex_path = self._resolve_project_file(tex_file)
        if not tex_path:
            self._status_message = "No TeX file found to compile."
            self._compile_log = tex_file
            self.statusMessageChanged.emit()
            self.compileLogChanged.emit()
            self.compileFinished.emit(False, "No TeX file found to compile.", tex_file)
            return

        self._current_main_tex_path = tex_path
        self._current_compile_tex_relative_path = Path(tex_file).as_posix()
        self._compiler.project_dir = Path(self._project_manager.get_project_dir())
        self._compiler.engine = self._current_compiler_engine()
        print("Current compiler engine:", self._compiler.engine)
        print("Compiling tex file:", self._current_compile_tex_relative_path)
        self._compiler.compile(tex_path)

    def _select_compile_tex_file(self) -> str:
        if not self._project_manager.has_project():
            return ""

        current_file = Path(self._current_file_relative_path).as_posix()
        if current_file.lower().endswith(".tex") and self._resolve_project_file(current_file):
            return current_file
        return self._project_manager.find_main_tex()

    def _save_current_file(self, content: str, emit_status: bool) -> bool:
        target_file = self._resolve_project_file(self._current_file_relative_path)
        if not target_file:
            if emit_status:
                self._set_file_status(False, "No file to save.", "No file to save.")
            return False
        if target_file.suffix.lower() not in TEXT_OPENABLE_EXTENSIONS:
            message = "Image preview mode does not need saving."
            if emit_status:
                self._set_file_status(False, message, self._current_file_relative_path)
                self._set_warning_problem(message, self._current_file_relative_path)
            return False

        success = write_text_file(str(target_file), content)
        if success:
            normalized_path = self._current_file_relative_path
            self._open_file_contents[normalized_path] = content
            self._modified_files.discard(normalized_path)
            self._add_open_file(normalized_path)
            self.openFilesChanged.emit()
        if emit_status:
            if success:
                self._set_file_status(True, "File saved.", f"Saved {target_file}")
            else:
                self._set_file_status(False, "Failed to save file.", str(target_file))
        return success

    def _add_open_file(self, relative_path: str) -> None:
        if relative_path and relative_path not in self._open_files:
            self._open_files.append(relative_path)

    def _set_file_status(self, success: bool, message: str, log_text: str) -> None:
        self._status_message = message
        self._compile_log = log_text
        self.statusMessageChanged.emit()
        self.compileLogChanged.emit()
        self.fileStatusChanged.emit(success, message, log_text)

    def _current_compiler_engine(self) -> str:
        compiler = self._settings.get("compilerEngine") or self._settings.get("compiler") or "xelatex"
        return compiler if compiler in {"xelatex", "pdflatex", "latexmk"} else "xelatex"

    def _set_warning_problem(self, message: str, file_path: str) -> None:
        self._problems = [{
            "type": "warning",
            "file": file_path,
            "line": -1,
            "message": message,
        }]
        self.problemsUpdated.emit(self._problems)

    def _handle_compile_started(self) -> None:
        engine = self._current_compiler_engine()
        self._status_message = f"Compiling with {engine}..."
        self._compile_log = (
            f"Compiler: {engine}\n"
            f"Target: {self._current_compile_tex_relative_path}\n"
            f"Running {self._compiler.command_preview(self._current_compile_tex_relative_path)}"
        )
        self._preview_image_path = ""
        self._preview_image_paths = []
        self._problems = [{
            "type": "info",
            "file": self._current_compile_tex_relative_path,
            "line": -1,
            "message": f"{self._status_message} Target: {self._current_compile_tex_relative_path}",
        }]
        self.statusMessageChanged.emit()
        self.compileLogChanged.emit()
        self.previewImagePathChanged.emit()
        self.previewImagePathsChanged.emit()
        self.problemsUpdated.emit(self._problems)
        self.compileStarted.emit()

    def _handle_compile_finished(self, success: bool, message: str, log_text: str) -> None:
        engine = self._current_compiler_engine()
        pdf_path = self._current_main_tex_path.with_suffix(".pdf")
        if success:
            message = f"Compile succeeded. PDF generated: {pdf_path.name}"
            print("Generated PDF:", pdf_path)
        else:
            message = f"Compile failed: {self._current_compile_tex_relative_path}"
        self._status_message = message
        self._compile_log = f"Compiler: {engine}\n{log_text}".strip()
        parsed_problems = self._log_parser.parse(self._compile_log, self._current_compile_tex_relative_path)
        if parsed_problems:
            self._problems = parsed_problems
        else:
            self._problems = [{
                "type": "info" if success else "error",
                "file": self._current_compile_tex_relative_path,
                "line": -1,
                "message": message,
            }]
        self.statusMessageChanged.emit()
        self.compileLogChanged.emit()
        self.problemsUpdated.emit(self._problems)
        self.compileFinished.emit(success, message, self._compile_log)
        if success:
            self._render_preview()

    def _render_preview(self) -> None:
        page_paths = self._pdf_renderer.render_all_pages(str(self._current_main_tex_path.with_suffix(".pdf")))
        page_urls = [
            QUrl.fromLocalFile(str(Path(page_path))).toString()
            for page_path in page_paths
            if Path(page_path).exists()
        ]
        if page_urls:
            self._preview_image_paths = page_urls
            self._preview_image_path = page_urls[0]
            self.previewImagePathsChanged.emit()
            self.previewImagePathChanged.emit()
            self.previewPagesUpdated.emit(page_urls)
            self.previewUpdated.emit(page_urls[0])
            return

        message = self._pdf_renderer.last_error or "Failed to render PDF preview."
        self._status_message = message
        self._compile_log = f"{self._compile_log}\n\n{message}".strip()
        self.statusMessageChanged.emit()
        self.compileLogChanged.emit()
        self.previewFailed.emit(message)

    def _ensure_default_main_tex(self) -> None:
        if not self._project_manager.has_project():
            return

        project_dir = Path(self._project_manager.get_project_dir())
        main_tex = project_dir / "main.tex"
        if not main_tex.exists():
            write_text_file(str(main_tex), DEFAULT_MAIN_TEX)

    def _path_from_qml(self, path: str) -> Path:
        if path.startswith("file:"):
            return Path(QUrl(path).toLocalFile()).resolve()
        return Path(path).resolve()

    def _resolve_project_file(self, relative_path: str) -> Path | None:
        if not relative_path:
            return None
        project_dir_text = self._project_manager.get_project_dir()
        if not project_dir_text:
            return None
        project_dir = Path(project_dir_text).resolve()
        file_path = (project_dir / relative_path).resolve()
        try:
            file_path.relative_to(project_dir)
        except ValueError:
            return None
        if not file_path.exists() or not file_path.is_file():
            return None
        return file_path

    statusMessage = Property(str, get_status_message, notify=statusMessageChanged)
    compileLog = Property(str, get_compile_log, notify=compileLogChanged)
    previewImagePath = Property(str, get_preview_image_path, notify=previewImagePathChanged)
    previewImagePaths = Property("QVariantList", get_preview_image_paths, notify=previewImagePathsChanged)
    problems = Property("QVariantList", get_problems, notify=problemsUpdated)
    projectFiles = Property("QVariantList", get_project_files, notify=projectFilesChanged)
    projectTree = Property("QVariantList", get_project_tree, notify=projectTreeChanged)
    openFiles = Property("QVariantList", get_open_files, notify=openFilesChanged)
    projectName = Property(str, get_project_name, notify=projectNameChanged)
    currentFileName = Property(str, get_current_file_name, notify=currentFileNameChanged)
    currentFileType = Property(str, get_current_file_type, notify=currentFileTypeChanged)
    currentLanguage = Property(str, get_current_language, notify=languageChanged)
