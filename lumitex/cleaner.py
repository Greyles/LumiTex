import shutil
from pathlib import Path


class LatexCleaner:
    AUX_SUFFIXES = {
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
    }
    AUX_COMPOUND_SUFFIXES = {
        ".synctex.gz",
        ".run.xml",
    }
    CLEAN_DIRS = {".lumitex_cache"}
    PROTECTED_DIRS = {"figures", "images", "img", "templates"}

    def clean_aux_files(self, project_dir: str) -> dict:
        root = Path(project_dir).resolve()
        if not root.exists() or not root.is_dir():
            return {
                "success": False,
                "deleted_count": 0,
                "deleted_files": [],
                "message": "Failed to clean auxiliary files. Project directory not found.",
            }

        deleted_files: list[str] = []

        for path in self._iter_clean_candidates(root):
            if not self._is_inside_project(root, path):
                continue

            relative_path = path.relative_to(root).as_posix()
            try:
                if path.is_dir() and path.name in self.CLEAN_DIRS:
                    shutil.rmtree(path)
                    deleted_files.append(relative_path + "/")
                elif path.is_file() and self._is_aux_file(path):
                    path.unlink()
                    deleted_files.append(relative_path)
            except OSError:
                return {
                    "success": False,
                    "deleted_count": len(deleted_files),
                    "deleted_files": deleted_files,
                    "message": "Failed to clean auxiliary files.",
                }

        deleted_count = len(deleted_files)
        message = (
            f"Cleaned {deleted_count} auxiliary files."
            if deleted_count > 0
            else "No auxiliary files found."
        )
        return {
            "success": True,
            "deleted_count": deleted_count,
            "deleted_files": deleted_files,
            "message": message,
        }

    def _iter_clean_candidates(self, root: Path):
        for path in root.iterdir():
            if path.is_dir():
                if path.name in self.CLEAN_DIRS:
                    yield path
                    continue
                if path.name in self.PROTECTED_DIRS or path.name.startswith("."):
                    continue
                for child in path.iterdir():
                    if child.is_file() and self._is_aux_file(child):
                        yield child
                    elif child.is_dir() and child.name in self.CLEAN_DIRS:
                        yield child
                continue

            if path.is_file() and self._is_aux_file(path):
                yield path

    def _is_aux_file(self, path: Path) -> bool:
        suffix = path.suffix.lower()
        suffixes = "".join(path.suffixes).lower()
        return suffix in self.AUX_SUFFIXES or suffixes in self.AUX_COMPOUND_SUFFIXES

    def _is_inside_project(self, root: Path, path: Path) -> bool:
        try:
            path.resolve().relative_to(root)
            return True
        except ValueError:
            return False
