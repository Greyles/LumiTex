import re


class LogParser:
    FILE_LINE_PATTERN = re.compile(r"^(?P<file>[^:\r\n]+\.(?:tex|bib|cls|sty)):(?P<line>\d+):\s*(?P<message>.+)$")
    LATEX_WARNING_PATTERN = re.compile(r"^(?P<message>LaTeX Warning:\s+.+)$")
    PACKAGE_WARNING_PATTERN = re.compile(r"^(?P<message>Package\s+\S+\s+Warning:\s+.+)$")

    def parse(self, log_text: str, default_file: str = "") -> list[dict[str, str | int]]:
        problems: list[dict[str, str | int]] = []
        seen: set[tuple[str, str, int, str]] = set()

        for raw_line in log_text.splitlines():
            line = raw_line.strip()
            if not line:
                continue

            file_line_match = self.FILE_LINE_PATTERN.match(line)
            if file_line_match:
                message = file_line_match.group("message").strip()
                problem_type = "warning" if "Warning:" in message else "error"
                self._append_problem(
                    problems,
                    seen,
                    problem_type,
                    file_line_match.group("file").replace("\\", "/"),
                    int(file_line_match.group("line")),
                    message,
                )
                continue

            latex_warning_match = self.LATEX_WARNING_PATTERN.match(line)
            if latex_warning_match:
                self._append_problem(
                    problems,
                    seen,
                    "warning",
                    default_file,
                    -1,
                    latex_warning_match.group("message").strip(),
                )
                continue

            package_warning_match = self.PACKAGE_WARNING_PATTERN.match(line)
            if package_warning_match:
                self._append_problem(
                    problems,
                    seen,
                    "warning",
                    default_file,
                    -1,
                    package_warning_match.group("message").strip(),
                )

        return problems

    def _append_problem(
        self,
        problems: list[dict[str, str | int]],
        seen: set[tuple[str, str, int, str]],
        problem_type: str,
        file_name: str,
        line_number: int,
        message: str,
    ) -> None:
        key = (problem_type, file_name, line_number, message)
        if key in seen:
            return
        seen.add(key)
        problems.append({
            "type": problem_type,
            "file": file_name,
            "line": line_number,
            "message": message,
        })
