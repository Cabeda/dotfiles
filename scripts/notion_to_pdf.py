#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "notion-client>=2.2.1",
#     "weasyprint>=62.0",
#     "markdown>=3.5",
#     "requests>=2.31",
#     "python-dotenv>=1.0",
#     "Pillow>=10.0",
# ]
# ///
"""
Notion to PDF Book Generator

This script connects to Notion and generates a PDF book from a page.
Optionally, you can include all subpages with --recursive. Features:
- Table of contents with clickable links
- Page numbers
- Markdown formatting preserved
- Images included
- Subpages as sub-chapters

Usage:
    export NOTION_API_KEY="your-notion-integration-token"
    uv run notion_to_pdf.py <page_id> [--output book.pdf] [--recursive]

To get your Notion API key:
1. Go to https://www.notion.so/my-integrations
2. Create a new integration
3. Copy the Internal Integration Token
4. Share the page(s) you want to export with your integration
"""

import argparse
import base64
import concurrent.futures
import hashlib
import os
import re
import sys
import tempfile
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional
from urllib.parse import urlparse

import markdown
import requests
from dotenv import load_dotenv
from notion_client import Client
from notion_client.errors import APIResponseError


def _prepare_weasyprint_env() -> None:
    """Ensure WeasyPrint can locate Homebrew shared libs on macOS."""
    brew_lib_paths = ["/opt/homebrew/lib", "/usr/local/lib"]
    existing_paths = [p for p in brew_lib_paths if Path(p).exists()]
    if not existing_paths:
        return

    current = os.environ.get("DYLD_FALLBACK_LIBRARY_PATH", "")
    parts = [p for p in current.split(":") if p]
    for path in existing_paths:
        if path not in parts:
            parts.insert(0, path)
    os.environ["DYLD_FALLBACK_LIBRARY_PATH"] = ":".join(parts)


def _import_weasyprint():
    """Import WeasyPrint after preparing dynamic library paths."""
    _prepare_weasyprint_env()
    from weasyprint import HTML, CSS  # type: ignore

    return HTML, CSS


@dataclass
class PageContent:
    """Represents a Notion page with its content and children."""
    id: str
    title: str
    content: str
    level: int = 0
    children: list["PageContent"] = field(default_factory=list)
    page_number: int = 0


class NotionToPDF:
    """Converts Notion pages to a PDF book."""

    def __init__(
        self,
        notion_token: str,
        verbose: bool = False,
        recursive: bool = False,
        max_depth: Optional[int] = None,
        log_level: str = "info",
        include_toc: bool = True,
        no_images: bool = False,
        css_path: Optional[str] = None,
        font_family: Optional[str] = None,
        author: Optional[str] = None,
        source_url: Optional[str] = None,
        notion_client: Optional[Client] = None,
        image_cache_dir: Optional[str] = None,
        image_workers: int = 1,
    ):
        self.notion = notion_client or Client(auth=notion_token)
        self.image_cache: dict[str, str] = {}
        self.image_futures: dict[str, concurrent.futures.Future[tuple[Optional[bytes], str]]] = {}
        self.image_cache_dir = Path(image_cache_dir) if image_cache_dir else None
        if self.image_cache_dir:
            self.image_cache_dir.mkdir(parents=True, exist_ok=True)
        self.image_workers = max(1, image_workers)
        self.executor = None
        if self.image_workers > 1:
            self.executor = concurrent.futures.ThreadPoolExecutor(
                max_workers=self.image_workers,
                thread_name_prefix="notion-img",
            )
        self.temp_dir = tempfile.mkdtemp()
        self.verbose = verbose
        self.log_level = "debug" if verbose else log_level.lower()
        self.recursive = recursive
        self.max_depth = max_depth
        self.include_toc = include_toc
        self.no_images = no_images
        self.css_path = css_path
        self.font_family = font_family
        self.author = author
        self.source_url = source_url
        self.page_ids: set[str] = set()

    def log(self, message: str, level: str = "info") -> None:
        """Emit logs filtered by level."""
        order = {"error": 0, "warn": 1, "info": 2, "debug": 3}
        current = order.get(self.log_level, 2)
        target = order.get(level, 2)
        if target <= current:
            print(f"[{level.upper()}] {message}", file=sys.stderr)

    def _with_retry(self, fn, *, desc: str, max_attempts: int = 3, sleep_base: float = 0.5):
        """Execute fn with basic retry/backoff on transient errors."""
        attempt = 0
        while True:
            try:
                return fn()
            except APIResponseError as e:
                if e.status in (429, 500, 502, 503, 504) and attempt < max_attempts - 1:
                    delay = sleep_base * (2 ** attempt)
                    self.log(f"Retrying {desc} after {delay:.1f}s due to {e.status}", "warn")
                    time.sleep(delay)
                    attempt += 1
                    continue
                raise
            except requests.RequestException as e:
                if attempt < max_attempts - 1:
                    delay = sleep_base * (2 ** attempt)
                    self.log(f"Retrying {desc} after {delay:.1f}s due to network error {e}", "warn")
                    time.sleep(delay)
                    attempt += 1
                    continue
                raise

    def get_page_title(self, page_id: str) -> str:
        """Get the title of a Notion page."""
        self.log(f"Fetching title for page {page_id}")
        page = self._with_retry(
            lambda: self.notion.pages.retrieve(page_id=page_id),
            desc=f"page title for {page_id}",
        )
        properties = page.get("properties", {})
        
        # Try different title property names
        for prop_name in ["title", "Title", "Name", "name"]:
            if prop_name in properties:
                title_prop = properties[prop_name]
                if title_prop.get("type") == "title":
                    title_array = title_prop.get("title", [])
                    if title_array:
                        return "".join(t.get("plain_text", "") for t in title_array)
        
        # Fallback: try to get from page title directly
        if "title" in page:
            return "".join(t.get("plain_text", "") for t in page["title"])
        
        return "Untitled"

    def get_child_pages(self, page_id: str) -> list[str]:
        """Get all child page IDs of a page."""
        child_pages = []
        self.log(f"Listing child pages for {page_id}")
        start_cursor = None
        has_more = True
        while has_more:
            response = self._with_retry(
                lambda: self.notion.blocks.children.list(
                    block_id=page_id, start_cursor=start_cursor
                ),
                desc=f"child pages for {page_id}",
            )
            for block in response.get("results", []):
                if block.get("type") == "child_page":
                    child_pages.append(block["id"])
                elif block.get("type") == "child_database":
                    # Skip databases for now
                    pass
            has_more = response.get("has_more", False)
            start_cursor = response.get("next_cursor")
        
        return child_pages

    def download_image(self, url: str) -> Optional[str]:
        """Download an image and return its base64 data URI."""
        if self.no_images:
            self.log(f"Skipping image (disabled): {url}", "debug")
            return None
        # Honor pre-embedded data URLs without fetching.
        if url.startswith("data:"):
            self.log("Image already embedded as data URI; skipping download", "debug")
            return url
        if url in self.image_cache:
            return self.image_cache[url]

        cache_hit = self._load_image_from_disk(url)
        if cache_hit:
            self.image_cache[url] = cache_hit
            return cache_hit

        try:
            if self.executor:
                future = self.image_futures.get(url)
                if not future:
                    future = self.executor.submit(self._download_image_bytes, url)
                    self.image_futures[url] = future
                content, content_type = future.result()
            else:
                content, content_type = self._download_image_bytes(url)

            if content is None or not isinstance(content, (bytes, bytearray)):
                return None

            data_uri = self._encode_image(bytes(content), str(content_type))
            self.image_cache[url] = data_uri
            self._save_image_to_disk(url, bytes(content), str(content_type))
            return data_uri
        except Exception as e:
            self.log(f"Warning: Failed to download image {url}: {e}", "warn")
            return None

    def _download_image_bytes(self, url: str) -> tuple[Optional[bytes], str]:
        response = self._with_retry(
            lambda: requests.get(url, timeout=30),
            desc=f"image {url}",
        )
        response.raise_for_status()
        content_type = response.headers.get("content-type", "image/png")
        if ";" in content_type:
            content_type = content_type.split(";")[0]
        return response.content, content_type

    def _encode_image(self, content: bytes, content_type: str) -> str:
        b64_data = base64.b64encode(content).decode("utf-8")
        return f"data:{content_type};base64,{b64_data}"

    def _cache_paths(self, url: str) -> tuple[Optional[Path], Optional[Path]]:
        if not self.image_cache_dir:
            return None, None
        digest = hashlib.sha256(url.encode("utf-8")).hexdigest()
        return (
            self.image_cache_dir / f"{digest}.bin",
            self.image_cache_dir / f"{digest}.ct",
        )

    def _load_image_from_disk(self, url: str) -> Optional[str]:
        data_path, ct_path = self._cache_paths(url)
        if not data_path or not data_path.exists():
            return None
        try:
            content = data_path.read_bytes()
            content_type = "image/png"
            if ct_path and ct_path.exists():
                content_type = ct_path.read_text(encoding="utf-8").strip() or content_type
            return self._encode_image(content, content_type)
        except OSError:
            return None

    def _save_image_to_disk(self, url: str, content: bytes, content_type: str) -> None:
        data_path, ct_path = self._cache_paths(url)
        if not data_path:
            return
        try:
            data_path.write_bytes(content)
            if ct_path:
                ct_path.write_text(content_type, encoding="utf-8")
        except OSError:
            self.log(f"Could not persist image cache for {url}", "debug")

    def rich_text_to_markdown(self, rich_text: list) -> str:
        """Convert Notion rich text to Markdown."""
        result = []
        for text in rich_text:
            content = text.get("plain_text", "")
            annotations = text.get("annotations", {})
            
            # Apply formatting
            if annotations.get("code"):
                content = f"`{content}`"
            if annotations.get("bold"):
                content = f"**{content}**"
            if annotations.get("italic"):
                content = f"*{content}*"
            if annotations.get("strikethrough"):
                content = f"~~{content}~~"
            if annotations.get("underline"):
                content = f"<u>{content}</u>"
            
            # Handle links
            if text.get("href"):
                href = self.normalize_link(text["href"])
                content = f"[{content}]({href})"
            
            result.append(content)
        
        return "".join(result)

    def block_to_markdown(self, block: dict, indent: int = 0) -> str:
        """Convert a Notion block to Markdown."""
        block_type = block.get("type")
        block_data = block.get(block_type, {})
        indent_str = "    " * indent
        
        if block_type == "paragraph":
            text = self.rich_text_to_markdown(block_data.get("rich_text", []))
            return f"{indent_str}{text}\n\n" if text else "\n"
        
        elif block_type in ["heading_1", "heading_2", "heading_3"]:
            text = self.rich_text_to_markdown(block_data.get("rich_text", []))
            level = int(block_type[-1])
            return f"{indent_str}{'#' * level} {text}\n\n"
        
        elif block_type == "bulleted_list_item":
            text = self.rich_text_to_markdown(block_data.get("rich_text", []))
            return f"{indent_str}- {text}\n"
        
        elif block_type == "numbered_list_item":
            text = self.rich_text_to_markdown(block_data.get("rich_text", []))
            return f"{indent_str}1. {text}\n"
        
        elif block_type == "to_do":
            text = self.rich_text_to_markdown(block_data.get("rich_text", []))
            checked = "x" if block_data.get("checked") else " "
            return f"{indent_str}- [{checked}] {text}\n"
        
        elif block_type == "toggle":
            text = self.rich_text_to_markdown(block_data.get("rich_text", []))
            return f"{indent_str}<details>\n{indent_str}<summary>{text}</summary>\n\n"
        
        elif block_type == "code":
            text = self.rich_text_to_markdown(block_data.get("rich_text", []))
            language = block_data.get("language", "")
            return f"{indent_str}```{language}\n{text}\n{indent_str}```\n\n"
        
        elif block_type == "quote":
            text = self.rich_text_to_markdown(block_data.get("rich_text", []))
            lines = text.split("\n")
            quoted = "\n".join(f"{indent_str}> {line}" for line in lines)
            return f"{quoted}\n\n"
        
        elif block_type == "callout":
            text = self.rich_text_to_markdown(block_data.get("rich_text", []))
            icon = block_data.get("icon", {})
            emoji = icon.get("emoji", "💡") if icon.get("type") == "emoji" else "💡"
            return f"{indent_str}> {emoji} {text}\n\n"
        
        elif block_type == "divider":
            return f"{indent_str}---\n\n"
        
        elif block_type == "image":
            image_data = block_data
            image_url = None
            caption = ""
            
            if image_data.get("type") == "external":
                image_url = image_data.get("external", {}).get("url")
            elif image_data.get("type") == "file":
                image_url = image_data.get("file", {}).get("url")
            
            if image_data.get("caption"):
                caption = self.rich_text_to_markdown(image_data["caption"])
            
            if image_url:
                # Download and embed image
                data_uri = self.download_image(image_url)
                if data_uri:
                    if caption:
                        return f'{indent_str}<figure><img src="{data_uri}" alt="{caption}"><figcaption>{caption}</figcaption></figure>\n\n'
                    return f'{indent_str}<img src="{data_uri}" alt="image">\n\n'
            return ""
        
        elif block_type == "bookmark":
            url = block_data.get("url", "")
            caption = self.rich_text_to_markdown(block_data.get("caption", []))
            return f"{indent_str}[{caption or url}]({url})\n\n"
        
        elif block_type == "embed":
            url = block_data.get("url", "")
            return f"{indent_str}[Embedded content]({url})\n\n"
        
        elif block_type == "table":
            return self.render_table(block["id"], block_data, indent)
        
        elif block_type == "table_row":
            cells = block_data.get("cells", [])
            row = " | ".join(self.rich_text_to_markdown(cell) for cell in cells)
            return f"{indent_str}| {row} |\n"
        
        elif block_type == "child_page":
            # Skip child pages - they're handled separately
            return ""
        
        elif block_type == "child_database":
            return ""
        
        return ""

    def normalize_link(self, href: str) -> str:
        """Map internal Notion links to local anchors when possible."""
        if "notion.so" in href or "notion.site" in href:
            page_id = clean_page_id(href)
            cleaned = page_id.replace("-", "")
            if cleaned in self.page_ids:
                return f"#page-{page_id}"
        return href

    def render_table(self, block_id: str, table_data: dict, indent: int = 0) -> str:
        """Render a Notion table block (excluding databases)."""
        rows: list[list[str]] = []
        indent_str = "    " * indent
        start_cursor = None
        has_more = True
        while has_more:
            response = self._with_retry(
                lambda: self.notion.blocks.children.list(
                    block_id=block_id, start_cursor=start_cursor
                ),
                desc=f"table rows for {block_id}",
            )
            for row_block in response.get("results", []):
                if row_block.get("type") != "table_row":
                    continue
                cells = row_block.get("table_row", {}).get("cells", [])
                row = []
                for cell in cells:
                    row.append(self.rich_text_to_markdown(cell))
                rows.append(row)
            has_more = response.get("has_more", False)
            start_cursor = response.get("next_cursor")

        if not rows:
            return ""

        has_col_header = table_data.get("has_column_header", False)
        has_row_header = table_data.get("has_row_header", False)

        def format_row(row: list[str]) -> str:
            cells = row.copy()
            if has_row_header and cells:
                cells[0] = f"**{cells[0]}**"
            return f"| {' | '.join(cells)} |"

        lines = []
        header_row = rows[0] if has_col_header else None
        body_rows = rows[1:] if has_col_header else rows

        if header_row:
            lines.append(indent_str + format_row(header_row))
            sep = " | ".join(["---"] * len(header_row))
            lines.append(indent_str + f"| {sep} |")

        for row in body_rows:
            lines.append(indent_str + format_row(row))

        return "\n".join(lines) + "\n\n"

    def get_page_content(self, page_id: str) -> str:
        """Get all content from a Notion page as Markdown."""
        content_parts = []
        
        def fetch_blocks(block_id: str, indent: int = 0):
            """Recursively fetch blocks."""
            has_more = True
            cursor = None
            
            while has_more:
                if cursor:
                    response = self._with_retry(
                        lambda: self.notion.blocks.children.list(
                            block_id=block_id, start_cursor=cursor
                        ),
                        desc=f"blocks for {block_id}",
                    )
                else:
                    response = self._with_retry(
                        lambda: self.notion.blocks.children.list(block_id=block_id),
                        desc=f"blocks for {block_id}",
                    )
                self.log(
                    f"Fetched {len(response.get('results', []))} blocks"
                    f" (has_more={response.get('has_more', False)}) for {block_id}"
                )
                
                for block in response.get("results", []):
                    md = self.block_to_markdown(block, indent)
                    if md:
                        content_parts.append(md)
                    if block.get("type") == "table":
                        # Table children already rendered
                        continue
                    
                    # Handle nested blocks
                    if block.get("has_children") and block.get("type") != "child_page":
                        fetch_blocks(block["id"], indent + 1)
                        
                        # Close toggle if needed
                        if block.get("type") == "toggle":
                            content_parts.append("</details>\n\n")
                
                has_more = response.get("has_more", False)
                cursor = response.get("next_cursor")
        
        fetch_blocks(page_id)
        return "".join(content_parts)

    def build_page_tree(self, page_id: str, level: int = 0) -> PageContent:
        """Build a tree of pages starting from the given page."""
        self.log(f"Building page tree for {page_id} at level {level}")
        title = self.get_page_title(page_id)
        content = self.get_page_content(page_id)
        
        page = PageContent(
            id=page_id,
            title=title,
            content=content,
            level=level,
        )
        
        if self.recursive:
            if self.max_depth is not None and level >= self.max_depth:
                self.log(
                    f"Max depth {self.max_depth} reached at {page_id}; not descending",
                    "debug",
                )
                return page
            # Get child pages
            child_page_ids = self.get_child_pages(page_id)
            self.log(f"Found {len(child_page_ids)} child pages for {page_id}")
            for child_id in child_page_ids:
                child_page = self.build_page_tree(child_id, level + 1)
                page.children.append(child_page)
        else:
            self.log(f"Recursion disabled; skipping child pages for {page_id}")
        
        return page

    def flatten_pages(self, page: PageContent) -> list[PageContent]:
        """Flatten the page tree into a list for sequential rendering."""
        pages = [page]
        for child in page.children:
            pages.extend(self.flatten_pages(child))
        return pages

    def generate_toc(self, pages: list[PageContent]) -> str:
        """Generate table of contents HTML."""
        toc_items = []
        for page in pages:
            indent = "    " * page.level
            toc_items.append(
                f'{indent}<li class="toc-level-{page.level}">'
                f'<a href="#page-{page.id}">{page.title}</a></li>'
            )
        
        return f"""
        <nav class="toc">
            <h1>Table of Contents</h1>
            <ul>
                {"".join(toc_items)}
            </ul>
        </nav>
        """

    def generate_html(self, root_page: PageContent) -> str:
        """Generate the full HTML document."""
        pages = self.flatten_pages(root_page)
        self.page_ids = {p.id.replace("-", "") for p in pages}
        
        # Generate TOC
        toc_html = self.generate_toc(pages) if self.include_toc else ""

        # Front matter (optional)
        front_matter_parts = []
        if self.author or self.source_url:
            front_matter_parts.append("<section class=\"front-matter\">")
            front_matter_parts.append("<h2>Document Info</h2><ul>")
            if self.author:
                front_matter_parts.append(f"<li><strong>Author:</strong> {self.author}</li>")
            if self.source_url:
                front_matter_parts.append(f"<li><strong>Source:</strong> <a href=\"{self.source_url}\">{self.source_url}</a></li>")
            front_matter_parts.append("</ul></section>")
        front_matter_html = "".join(front_matter_parts)
        
        # Generate content for each page
        content_parts = []
        md_converter = markdown.Markdown(
            extensions=["tables", "fenced_code", "toc", "nl2br"]
        )
        
        for i, page in enumerate(pages):
            page.page_number = i + 1
            heading_level = min(page.level + 1, 6)
            
            # Convert markdown to HTML
            page_html = md_converter.convert(page.content)
            md_converter.reset()
            
            content_parts.append(f"""
            <section class="chapter" id="page-{page.id}">
                <h{heading_level} class="chapter-title">{page.title}</h{heading_level}>
                <div class="chapter-content">
                    {page_html}
                </div>
            </section>
            """)
        
        # Full HTML document
        html = f"""
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <title>{root_page.title}</title>
        </head>
        <body>
            <header class="book-title">
                <h1>{root_page.title}</h1>
            </header>
            
            {front_matter_html}
            {toc_html}
            
            <main class="book-content">
                {"".join(content_parts)}
            </main>
        </body>
        </html>
        """
        
        return html

    def get_css(self) -> str:
        """Get the CSS for the PDF."""
        if self.css_path:
            try:
                return Path(self.css_path).read_text(encoding="utf-8")
            except OSError as e:
                self.log(f"Failed to read CSS override {self.css_path}: {e}", "warn")

        font_family = self.font_family or "'Georgia', 'Times New Roman', serif"
        css_template = """
        @page {
            size: A4;
            margin: 2cm 2cm 3cm 2cm;
            
            @bottom-center {
                content: counter(page);
                font-size: 10pt;
                color: #666;
            }
            
            @bottom-right {
                content: string(chapter-title);
                font-size: 9pt;
                color: #999;
            }
        }
        
        @page :first {
            @bottom-center {
                content: none;
            }
            @bottom-right {
                content: none;
            }
        }
        
        * {
            box-sizing: border-box;
        }
        
        body {
            font-family: {FONT_FAMILY};
            font-size: 11pt;
            line-height: 1.6;
            color: #333;
        }

        .front-matter {
            margin: 1em 0 2em 0;
            padding: 1em;
            background: #f8f8f8;
            border: 1px solid #e0e0e0;
            border-radius: 6px;
        }

        .front-matter h2 {
            margin-top: 0;
        }
        
        .book-title {
            page-break-after: always;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            text-align: center;
        }
        
        .book-title h1 {
            font-size: 32pt;
            font-weight: bold;
            color: #1a1a1a;
        }
        
        .toc {
            page-break-after: always;
        }
        
        .toc h1 {
            font-size: 24pt;
            margin-bottom: 1.5em;
            color: #1a1a1a;
        }
        
        .toc ul {
            list-style: none;
            padding-left: 0;
        }
        
        .toc li {
            margin: 0.5em 0;
            line-height: 1.8;
        }
        
        .toc a {
            color: #333;
            text-decoration: none;
        }
        
        .toc a::after {
            content: leader('.') target-counter(attr(href), page);
            color: #666;
        }
        
        .toc-level-0 { margin-left: 0; font-weight: bold; }
        .toc-level-1 { margin-left: 1.5em; }
        .toc-level-2 { margin-left: 3em; }
        .toc-level-3 { margin-left: 4.5em; }
        .toc-level-4 { margin-left: 6em; }
        
        .chapter {
            page-break-before: always;
        }
        
        .chapter-title {
            string-set: chapter-title content();
            font-weight: bold;
            margin-bottom: 1em;
            color: #1a1a1a;
            border-bottom: 2px solid #333;
            padding-bottom: 0.5em;
        }
        
        h1 { font-size: 24pt; }
        h2 { font-size: 20pt; }
        h3 { font-size: 16pt; }
        h4 { font-size: 14pt; }
        h5 { font-size: 12pt; }
        h6 { font-size: 11pt; }
        
        .chapter-content h1 { font-size: 18pt; margin-top: 1.5em; }
        .chapter-content h2 { font-size: 16pt; margin-top: 1.3em; }
        .chapter-content h3 { font-size: 14pt; margin-top: 1.2em; }
        
        p {
            margin: 0.8em 0;
            text-align: justify;
        }
        
        code {
            font-family: 'Courier New', monospace;
            font-size: 10pt;
            background-color: #f5f5f5;
            padding: 0.1em 0.3em;
            border-radius: 3px;
        }
        
        pre {
            background-color: #f5f5f5;
            padding: 1em;
            overflow-x: auto;
            border-radius: 5px;
            border: 1px solid #ddd;
        }
        
        pre code {
            background: none;
            padding: 0;
        }
        
        blockquote {
            border-left: 4px solid #ddd;
            margin: 1em 0;
            padding: 0.5em 1em;
            color: #555;
            background-color: #fafafa;
        }
        
        img {
            max-width: 100%;
            height: auto;
            display: block;
            margin: 1em auto;
        }
        
        figure {
            margin: 1em 0;
            text-align: center;
        }
        
        figcaption {
            font-size: 10pt;
            color: #666;
            font-style: italic;
            margin-top: 0.5em;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 1em 0;
            font-size: 10pt;
        }
        
        th, td {
            border: 1px solid #ddd;
            padding: 0.5em;
            text-align: left;
        }
        
        th {
            background-color: #f5f5f5;
            font-weight: bold;
        }
        
        ul, ol {
            margin: 0.8em 0;
            padding-left: 1.5em;
        }
        
        li {
            margin: 0.3em 0;
        }
        
        a {
            color: #0066cc;
            text-decoration: none;
        }
        
        details {
            margin: 1em 0;
            padding: 0.5em;
            background-color: #fafafa;
            border-radius: 5px;
        }
        
        summary {
            font-weight: bold;
            cursor: pointer;
        }
        
        hr {
            border: none;
            border-top: 1px solid #ddd;
            margin: 2em 0;
        }
        
        /* Ensure content doesn't break awkwardly */
        h1, h2, h3, h4, h5, h6 {
            page-break-after: avoid;
        }
        
        img, table, figure {
            page-break-inside: avoid;
        }
        """

        return css_template.replace("{FONT_FAMILY}", font_family)

    def generate_pdf(self, page_id: str, output_path: str) -> None:
        """Generate a PDF from a Notion page."""
        print(f"Fetching page tree from Notion...", file=sys.stderr)
        root_page = self.build_page_tree(page_id)

        output_path = self._resolve_output_path(output_path, root_page.title)
        
        print(f"Generating HTML...", file=sys.stderr)
        html_content = self.generate_html(root_page)
        
        print(f"Converting to PDF...", file=sys.stderr)
        HTML, CSS = _import_weasyprint()
        html = HTML(string=html_content)
        css = CSS(string=self.get_css())
        
        html.write_pdf(output_path, stylesheets=[css])
        print(f"PDF saved to: {output_path}", file=sys.stderr)

    def _resolve_output_path(self, output_path: str, title: str) -> str:
        """If output is a directory, derive filename from title."""
        path_obj = Path(output_path)
        if output_path.endswith(os.sep) or path_obj.is_dir():
            slug = re.sub(r"[^a-zA-Z0-9_-]+", "-", title).strip("-") or "notion-book"
            return str(path_obj / f"{slug}.pdf") if path_obj.is_dir() else str(Path(output_path) / f"{slug}.pdf")
        return output_path


def clean_page_id(page_id: str) -> str:
    """Clean and normalize a Notion page ID."""
    page_id = page_id.strip()

    # Handle full URLs
    if "notion.so" in page_id or "notion.site" in page_id:
        # Extract ID from URL
        parsed = urlparse(page_id)
        path = parsed.path.split("/")[-1]
        # Remove any query params and get the ID part
        path = path.split("?")[0]
        # ID is usually the last 32 chars (with or without dashes)
        if "-" in path:
            page_id = path.split("-")[-1]
        else:
            page_id = path[-32:]
    else:
        # If a title is prefixed (e.g., Title-<id>), extract the last 32 hex chars
        hex_chars = re.findall(r"[0-9a-fA-F]", page_id)
        if len(hex_chars) >= 32:
            page_id = "".join(hex_chars[-32:])
    
    # Remove dashes if present
    page_id = page_id.replace("-", "")
    
    # Format with dashes (Notion format: 8-4-4-4-12)
    if len(page_id) == 32:
        return f"{page_id[:8]}-{page_id[8:12]}-{page_id[12:16]}-{page_id[16:20]}-{page_id[20:]}"
    
    return page_id


def main():
    parser = argparse.ArgumentParser(
        description="Generate a PDF book from a Notion page and its subpages.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    # Using page ID
    %(prog)s abc123def456...

    # Using Notion URL
    %(prog)s "https://www.notion.so/My-Page-abc123def456..."

    # Specify output file
    %(prog)s abc123def456... --output my-book.pdf

    # Include subpages recursively
    %(prog)s abc123def456... --recursive

Environment Variables:
    NOTION_API_KEY    Your Notion integration token (required)
        """,
    )
    parser.add_argument(
        "page_id",
        help="Notion page ID or URL",
    )
    parser.add_argument(
        "-o", "--output",
        default="notion-book.pdf",
        help="Output PDF filename (default: notion-book.pdf)",
    )
    parser.add_argument(
        "-e", "--env-file",
        help="Path to .env file containing NOTION_API_KEY",
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Enable verbose logging",
    )
    parser.add_argument(
        "--log-level",
        choices=["error", "warn", "info", "debug"],
        default="info",
        help="Log level (overridden by --verbose)",
    )
    parser.add_argument(
        "-r", "--recursive",
        action="store_true",
        help="Include all subpages recursively",
    )
    parser.add_argument(
        "--max-depth",
        type=int,
        help="Maximum depth for recursive traversal (root = 0)",
    )
    parser.add_argument(
        "--no-toc",
        action="store_true",
        help="Do not include table of contents",
    )
    parser.add_argument(
        "--no-images",
        action="store_true",
        help="Skip downloading/embedding images",
    )
    parser.add_argument(
        "--css",
        dest="css_path",
        help="Path to custom CSS file",
    )
    parser.add_argument(
        "--font-family",
        help="Override base font family (e.g., 'Inter, sans-serif')",
    )
    parser.add_argument(
        "--author",
        help="Author name for front matter",
    )
    parser.add_argument(
        "--source-url",
        help="Source URL to display in front matter",
    )
    parser.add_argument(
        "--image-cache-dir",
        help="Directory to cache downloaded images",
    )
    parser.add_argument(
        "--image-workers",
        type=int,
        default=1,
        help="Parallel image download workers (default: 1)",
    )
    
    args = parser.parse_args()
    
    # Load environment variables
    if args.env_file:
        load_dotenv(args.env_file)
    else:
        load_dotenv()
    
    notion_token = os.getenv("NOTION_API_KEY")
    if not notion_token:
        print(
            "Error: NOTION_API_KEY environment variable not set.\n"
            "Please set it with: export NOTION_API_KEY='your-token'\n"
            "Or create a .env file with NOTION_API_KEY=your-token",
            file=sys.stderr,
        )
        sys.exit(1)
    
    # Clean the page ID
    page_id = clean_page_id(args.page_id)
    
    # Generate PDF
    converter = NotionToPDF(
        notion_token,
        verbose=args.verbose,
        recursive=args.recursive,
        max_depth=args.max_depth if args.recursive else None,
        log_level=args.log_level,
        include_toc=not args.no_toc,
        no_images=args.no_images,
        css_path=args.css_path,
        font_family=args.font_family,
        author=args.author,
        source_url=args.source_url,
        image_cache_dir=args.image_cache_dir,
        image_workers=args.image_workers,
    )
    try:
        converter.generate_pdf(page_id, args.output)
        print(f"\n✅ Successfully generated: {args.output}")
    except APIResponseError as e:
        print(
            "\n❌ Notion API error:\n"
            f"Status: {getattr(e, 'status', 'unknown')}\n"
            f"Code: {getattr(e, 'code', 'unknown')}\n"
            f"Message: {e}",
            file=sys.stderr,
        )
        print(
            "\nCommon fixes:\n"
            "- Share the page and all subpages with your integration.\n"
            "- Verify NOTION_API_KEY matches that integration's token.\n"
            "- Confirm the page ID/URL is correct (final ID:"
            f" {page_id}).",
            file=sys.stderr,
        )
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
