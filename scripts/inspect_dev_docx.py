import os
import sys
import zipfile
import xml.etree.ElementTree as ET


NS = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}


def find_target_docx(base_dir: str) -> str:
    for name in sorted(os.listdir(base_dir)):
        if name.endswith(".docx") and "项目开发文档" in name and not name.endswith(".bak"):
            return os.path.join(base_dir, name)
    raise FileNotFoundError("未找到目标项目开发文档 docx")


def load_paragraphs(docx_path: str):
    with zipfile.ZipFile(docx_path) as zf:
        root = ET.fromstring(zf.read("word/document.xml"))
    paragraphs = root.findall(".//w:body/w:p", NS)
    return paragraphs


def paragraph_text(paragraph) -> str:
    return "".join(node.text or "" for node in paragraph.findall(".//w:t", NS)).strip()


def main() -> int:
    base_dir = os.path.join(os.getcwd(), "docs")
    docx_path = find_target_docx(base_dir)
    print(f"DOCX: {docx_path}")
    paragraphs = load_paragraphs(docx_path)
    print(f"PARAGRAPH_COUNT: {len(paragraphs)}")

    focus_ranges = [(126, 145), (171, 195), (442, 497), (537, 652)]
    for start, end in focus_ranges:
        print(f"--- RANGE {start}-{end} ---")
        for idx in range(start, min(end + 1, len(paragraphs))):
            text = paragraph_text(paragraphs[idx])
            if text:
                print(f"{idx}: {text}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
