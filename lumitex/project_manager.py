from pathlib import Path


TEXT_OPENABLE_EXTENSIONS = {
    ".tex",
    ".bib",
    ".cls",
    ".sty",
    ".bst",
    ".bbx",
    ".cbx",
    ".md",
    ".txt",
    ".json",
    ".yaml",
    ".yml",
    ".py",
    ".qml",
}
IMAGE_PREVIEW_EXTENSIONS = {".png", ".jpg", ".jpeg", ".svg", ".gif", ".webp"}
BINARY_DISPLAY_EXTENSIONS = {".pdf", ".eps"} | IMAGE_PREVIEW_EXTENSIONS
DISPLAY_EXTENSIONS = TEXT_OPENABLE_EXTENSIONS | BINARY_DISPLAY_EXTENSIONS
IGNORED_EXTENSIONS = {
    ".aux",
    ".log",
    ".out",
    ".toc",
    ".lof",
    ".lot",
    ".fls",
    ".fdb_latexmk",
    ".bbl",
    ".blg",
    ".nav",
    ".snm",
    ".vrb",
    ".xdv",
    ".bcf",
    ".run.xml",
}
IGNORED_SUFFIXES = {".synctex.gz", ".fdb_latexmk", ".run.xml"}
IGNORED_NAMES = {"main.synctex.gz"}
IGNORED_DIRS = {
    "__pycache__",
    ".git",
    ".idea",
    ".vscode",
    ".lumitex_cache",
    "node_modules",
    "dist",
    "build",
}
MAX_SCAN_DEPTH = 3


class ProjectManager:
    def __init__(self, project_dir: str | Path | None = None) -> None:
        self._project_dir = Path(project_dir).resolve() if project_dir else None

    def set_project_dir(self, path: str) -> None:
        self._project_dir = Path(path).resolve()

    def clear_project(self) -> None:
        self._project_dir = None

    def has_project(self) -> bool:
        return self._project_dir is not None and self._project_dir.exists()

    def get_project_dir(self) -> str:
        return str(self._project_dir) if self._project_dir else ""

    def get_project_files(self) -> list[dict[str, str | bool | int]]:
        return self._flatten_tree(self.get_project_tree())

    def get_project_tree(self) -> list[dict[str, object]]:
        if not self._project_dir or not self._project_dir.exists():
            print("PROJECT DIR:", self._project_dir)
            print("PROJECT RAW FILE COUNT:", 0)
            print("PROJECT DISPLAY FILE COUNT:", 0)
            print("PROJECT TREE FILES:", [])
            print("PROJECT TREE:", [])
            return []

        tree = self._build_tree(self._project_dir, depth=0)
        raw_count = self._count_raw_files(self._project_dir, depth=0)
        display_files = self._collect_file_names(tree)
        print("PROJECT DIR:", self._project_dir)
        print("PROJECT RAW FILE COUNT:", raw_count)
        print("PROJECT DISPLAY FILE COUNT:", len(display_files))
        print("PROJECT TREE FILES:", display_files)
        print("PROJECT TREE:", tree)
        return tree

    def find_main_tex(self) -> str:
        if not self._project_dir:
            return ""

        main_tex = self._project_dir / "main.tex"
        if main_tex.exists():
            return "main.tex"

        tex_files = self._find_files_by_extension(self.get_project_tree(), ".tex")
        return str(tex_files[0]) if tex_files else ""

    def _build_tree(self, directory: Path, depth: int) -> list[dict[str, object]]:
        if depth >= MAX_SCAN_DEPTH:
            return []

        items: list[dict[str, object]] = []
        for child in sorted(directory.iterdir(), key=lambda path: (path.is_file(), path.name.lower())):
            if child.is_dir() and self._is_ignored_dir(child):
                continue

            if child.is_dir():
                child_items = self._build_tree(child, depth + 1)

                relative_path = child.relative_to(self._project_dir).as_posix()
                items.append({
                    "name": child.name,
                    "path": relative_path,
                    "relativePath": relative_path,
                    "type": "directory",
                    "extension": "",
                    "loadable": False,
                    "openable": False,
                    "isDir": True,
                    "depth": depth,
                    "children": child_items,
                })
                continue

            if not self._is_visible_file(child):
                continue

            relative_path = child.relative_to(self._project_dir).as_posix()
            openable = child.suffix.lower() in TEXT_OPENABLE_EXTENSIONS
            items.append({
                "name": child.name,
                "path": relative_path,
                "relativePath": relative_path,
                "type": "file",
                "extension": child.suffix.lower(),
                "loadable": True,
                "openable": openable,
                "previewable": child.suffix.lower() in IMAGE_PREVIEW_EXTENSIONS,
                "isDir": False,
                "depth": depth,
                "children": [],
            })

        return items

    def _is_visible_file(self, path: Path) -> bool:
        name = path.name.lower()
        suffixes = "".join(path.suffixes).lower()
        if name in IGNORED_NAMES or suffixes in IGNORED_SUFFIXES:
            return False
        if path.suffix.lower() in IGNORED_EXTENSIONS:
            return False
        return path.suffix.lower() in DISPLAY_EXTENSIONS

    def _is_ignored_dir(self, path: Path) -> bool:
        name = path.name.lower()
        return name in IGNORED_DIRS

    def _flatten_tree(self, nodes: list[dict[str, object]], depth: int = 0) -> list[dict[str, str | bool | int]]:
        items: list[dict[str, str | bool | int]] = []
        for node in nodes:
            relative_path = str(node.get("path", ""))
            is_dir = node.get("type") == "directory"
            parent_path = (
                relative_path.rsplit("/", 1)[0]
                if "/" in relative_path
                else ""
            )
            extension = str(node.get("extension", ""))
            items.append({
                "name": str(node.get("name", "")),
                "relativePath": relative_path,
                "path": relative_path,
                "parentPath": parent_path,
                "type": "folder" if is_dir else extension.lstrip("."),
                "extension": extension,
                "loadable": bool(node.get("loadable", False)),
                "openable": bool(node.get("openable", False)),
                "previewable": bool(node.get("previewable", False)),
                "isDir": bool(is_dir),
                "depth": depth,
            })
            if is_dir:
                children = node.get("children", [])
                if isinstance(children, list):
                    items.extend(self._flatten_tree(children, depth + 1))
        return items

    def _find_files_by_extension(self, nodes: list[dict[str, object]], extension: str) -> list[str]:
        matches: list[str] = []
        for node in nodes:
            if node.get("type") == "directory":
                children = node.get("children", [])
                if isinstance(children, list):
                    matches.extend(self._find_files_by_extension(children, extension))
                continue
            if str(node.get("extension", "")).lower() == extension:
                matches.append(str(node.get("path", "")))
        return matches

    def _count_raw_files(self, directory: Path, depth: int) -> int:
        if depth >= MAX_SCAN_DEPTH or not directory.exists():
            return 0

        count = 0
        for child in directory.iterdir():
            if child.is_dir():
                if self._is_ignored_dir(child):
                    continue
                count += self._count_raw_files(child, depth + 1)
            elif child.is_file():
                count += 1
        return count

    def _collect_file_names(self, nodes: list[dict[str, object]]) -> list[str]:
        names: list[str] = []
        for node in nodes:
            if node.get("type") == "directory":
                children = node.get("children", [])
                if isinstance(children, list):
                    names.extend(self._collect_file_names(children))
            else:
                names.append(str(node.get("path", node.get("name", ""))))
        return names
