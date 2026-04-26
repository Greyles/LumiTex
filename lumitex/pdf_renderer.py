from pathlib import Path


class PdfRenderer:
    def __init__(self) -> None:
        self.last_error = ""

    def render_first_page(self, pdf_path: str) -> str:
        pages = self.render_all_pages(pdf_path)
        if pages:
            return pages[0]
        return self.last_error or f"Failed to render PDF preview: {pdf_path}"

    def render_all_pages(self, pdf_path: str) -> list[str]:
        self.last_error = ""
        pdf_file = Path(pdf_path)
        if not pdf_file.exists():
            self.last_error = f"PDF not found: {pdf_file}"
            return []

        try:
            import fitz
        except ImportError:
            self.last_error = "PyMuPDF is not installed. Run pip install -r requirements.txt."
            return []

        try:
            output_dir = pdf_file.parent / ".lumitex_cache"
            output_dir.mkdir(parents=True, exist_ok=True)
            for old_preview in output_dir.glob("preview_page_*.png"):
                try:
                    old_preview.unlink()
                except OSError:
                    pass

            rendered_pages: list[str] = []

            with fitz.open(str(pdf_file)) as document:
                if document.page_count == 0:
                    self.last_error = f"PDF has no pages: {pdf_file}"
                    return []

                for page_index in range(document.page_count):
                    output_path = output_dir / f"preview_page_{page_index + 1}.png"
                    page = document.load_page(page_index)
                    pixmap = page.get_pixmap(matrix=fitz.Matrix(2, 2), alpha=False)
                    pixmap.save(str(output_path))
                    rendered_pages.append(str(output_path))

            return rendered_pages
        except Exception as exc:
            self.last_error = f"Failed to render PDF preview: {exc}"
            return []
