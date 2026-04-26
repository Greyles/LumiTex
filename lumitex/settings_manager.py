import json
from pathlib import Path


class SettingsManager:
    def __init__(self, settings_path: str | Path) -> None:
        self.settings_path = Path(settings_path)

    def get_default_settings(self) -> dict:
        return {
            "compilerEngine": "xelatex",
            "compiler": "xelatex",
            "editorFont": "Consolas",
            "fontSize": 15,
            "lineWrap": False,
            "defaultProjectDirectory": "",
            "theme": "light",
            "language": "zh",
        }

    def load_settings(self) -> dict:
        defaults = self.get_default_settings()
        if not self.settings_path.exists():
            print(f"[settings] load language={defaults['language']} theme={defaults['theme']}")
            return defaults

        try:
            loaded = json.loads(self.settings_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            print(f"[settings] load language={defaults['language']} theme={defaults['theme']}")
            return defaults

        if not isinstance(loaded, dict):
            print(f"[settings] load language={defaults['language']} theme={defaults['theme']}")
            return defaults

        if "compiler" in loaded and "compilerEngine" not in loaded:
            loaded["compilerEngine"] = loaded["compiler"]
        if "compilerEngine" in loaded:
            loaded["compiler"] = loaded["compilerEngine"]
        defaults.update(loaded)
        defaults["language"] = self._normalize_language(defaults.get("language"))
        defaults["theme"] = self._normalize_theme(defaults.get("theme"))
        defaults["compilerEngine"] = self._normalize_compiler(defaults.get("compilerEngine"))
        defaults["compiler"] = defaults["compilerEngine"]
        print(f"[settings] load language={defaults['language']} theme={defaults['theme']} compiler={defaults['compilerEngine']}")
        return defaults

    def save_settings(self, settings: dict) -> bool:
        try:
            merged = self.get_default_settings()
            if self.settings_path.exists():
                try:
                    loaded = json.loads(self.settings_path.read_text(encoding="utf-8"))
                except json.JSONDecodeError:
                    loaded = {}
                if isinstance(loaded, dict):
                    merged.update(loaded)

            incoming = dict(settings)
            if "language" in incoming:
                incoming["language"] = self._normalize_language(incoming.get("language"))
            if "theme" in incoming:
                incoming["theme"] = self._normalize_theme(incoming.get("theme"))
            if "compiler" in incoming and "compilerEngine" not in incoming:
                incoming["compilerEngine"] = incoming["compiler"]
            if "compilerEngine" in incoming:
                incoming["compiler"] = incoming["compilerEngine"]
            merged.update(incoming)
            merged["language"] = self._normalize_language(merged.get("language"))
            merged["theme"] = self._normalize_theme(merged.get("theme"))
            merged["compilerEngine"] = self._normalize_compiler(merged.get("compilerEngine"))
            merged["compiler"] = merged["compilerEngine"]
            if "compilerEngine" not in merged and "compiler" in merged:
                merged["compilerEngine"] = merged["compiler"]
            if "compiler" not in merged and "compilerEngine" in merged:
                merged["compiler"] = merged["compilerEngine"]
            self.settings_path.parent.mkdir(parents=True, exist_ok=True)
            self.settings_path.write_text(json.dumps(merged, indent=2), encoding="utf-8")
            print(f"[settings] save language={merged['language']} theme={merged['theme']} compiler={merged['compilerEngine']}")
            return True
        except (OSError, TypeError, ValueError):
            return False

    def _normalize_language(self, language: object) -> str:
        return "zh" if language == "zh" else "en"

    def _normalize_theme(self, theme: object) -> str:
        theme_value = str(theme or "").lower()
        if theme_value in {"dark", "light", "system"}:
            return theme_value
        return "light"

    def _normalize_compiler(self, compiler: object) -> str:
        return compiler if compiler in {"xelatex", "pdflatex", "latexmk"} else "xelatex"
