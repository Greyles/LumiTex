from pathlib import Path
import shutil


IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".pdf", ".eps", ".svg"}


def read_text_file(path: str) -> str:
    return Path(path).read_text(encoding="utf-8", errors="replace")


def write_text_file(path: str, content: str) -> bool:
    try:
        file_path = Path(path)
        file_path.parent.mkdir(parents=True, exist_ok=True)
        file_path.write_text(content, encoding="utf-8")
        return True
    except OSError:
        return False


def import_image_to_project(project_dir: str | Path, image_path: str | Path) -> dict[str, str | bool]:
    source_path = Path(image_path).expanduser().resolve()
    if not source_path.exists() or not source_path.is_file():
        return {
            "success": False,
            "message": "Failed to import image.",
        }

    if source_path.suffix.lower() not in IMAGE_EXTENSIONS:
        return {
            "success": False,
            "message": "Unsupported image format.",
        }

    try:
        project_path = Path(project_dir).resolve()
        figures_dir = project_path / "figures"
        figures_dir.mkdir(parents=True, exist_ok=True)

        target_path = _unique_target_path(figures_dir, source_path.name)
        shutil.copy2(source_path, target_path)
        relative_path = target_path.relative_to(project_path).as_posix()
        return {
            "success": True,
            "relative_path": relative_path,
            "file_name": target_path.name,
            "message": "Image imported.",
        }
    except OSError:
        return {
            "success": False,
            "message": "Failed to import image.",
        }


def _unique_target_path(directory: Path, file_name: str) -> Path:
    candidate = directory / file_name
    if not candidate.exists():
        return candidate

    stem = candidate.stem
    suffix = candidate.suffix
    index = 1
    while True:
        next_candidate = directory / f"{stem}_{index}{suffix}"
        if not next_candidate.exists():
            return next_candidate
        index += 1
