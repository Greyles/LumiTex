import json
import shutil
from pathlib import Path


class TemplateManager:
    def __init__(self, templates_dir: str | Path) -> None:
        self.templates_dir = Path(templates_dir).resolve()

    def list_templates(self) -> list[dict[str, str]]:
        templates: list[dict[str, str]] = []
        if not self.templates_dir.exists():
            return templates

        for template_dir in sorted(self.templates_dir.iterdir(), key=lambda path: path.name.lower()):
            if not template_dir.is_dir():
                continue
            metadata = self._read_metadata(template_dir)
            if not metadata:
                continue
            templates.append({
                "id": template_dir.name,
                "name": metadata.get("name", template_dir.name),
                "description": metadata.get("description", ""),
                "main_file": metadata.get("main_file", "main.tex"),
                "compiler": metadata.get("compiler", "xelatex"),
            })
        return templates

    def create_project_from_template(self, template_id: str, target_dir: str, project_name: str) -> dict:
        clean_name = self._clean_project_name(project_name)
        if not clean_name:
            return {"success": False, "message": "Project name is required.", "project_dir": ""}

        template_dir = (self.templates_dir / template_id).resolve()
        if not self._is_template_dir(template_dir):
            return {"success": False, "message": "Template not found.", "project_dir": ""}

        target_root = Path(target_dir).resolve()
        project_dir = target_root / clean_name
        if project_dir.exists():
            return {"success": False, "message": "Project directory already exists.", "project_dir": str(project_dir)}

        metadata = self._read_metadata(template_dir)
        if not metadata:
            return {"success": False, "message": "Template metadata is invalid.", "project_dir": ""}

        try:
            target_root.mkdir(parents=True, exist_ok=True)
            shutil.copytree(template_dir, project_dir)
            lumitex_config = {
                "project_name": clean_name,
                "main_file": metadata.get("main_file", "main.tex"),
                "compiler": metadata.get("compiler", "xelatex"),
                "template": template_id,
            }
            (project_dir / "lumitex.json").write_text(
                json.dumps(lumitex_config, indent=2),
                encoding="utf-8",
            )
        except OSError as exc:
            return {"success": False, "message": f"Failed to create project: {exc}", "project_dir": str(project_dir)}

        return {"success": True, "message": "Project created.", "project_dir": str(project_dir)}

    def _read_metadata(self, template_dir: Path) -> dict:
        metadata_path = template_dir / "template.json"
        if not metadata_path.exists():
            return {}
        try:
            return json.loads(metadata_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return {}

    def _is_template_dir(self, template_dir: Path) -> bool:
        try:
            template_dir.relative_to(self.templates_dir)
        except ValueError:
            return False
        return template_dir.is_dir() and (template_dir / "template.json").exists()

    def _clean_project_name(self, project_name: str) -> str:
        return "".join(char for char in project_name.strip() if char not in '<>:"/\\|?*')
