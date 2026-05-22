#!/usr/bin/env python3
"""
Self-host the Medium images for your blog posts.

What it does:
  1. Scans your posts for Medium CDN image URLs (cdn-images-1.medium.com).
  2. Downloads each image into  assets/img/medium/  with a clean, descriptive
     filename based on the post slug (e.g. what-writing-taught-me-about-quality-1.jpeg).
  3. Auto-detects the real file type (handles the Medium URLs that have no
     extension) from the HTTP Content-Type / magic bytes.
  4. Rewrites the posts in place so banner + inline images point at the local
     copies (/assets/img/medium/...).

Run it from your repo root (the folder that contains _posts and assets):

    python3 download-medium-images.py

Options:
    --posts   DIR   folder containing the .md posts   (default: _posts)
    --assets  DIR   where to save images              (default: assets/img/medium)
    --prefix  PATH  URL prefix used in the posts       (default: /assets/img/medium)
    --dry-run       show what would happen, change nothing

No third-party packages required (uses the Python standard library).
"""
import argparse, os, re, sys, urllib.request

URL_RE = re.compile(r'https://cdn-images-1\.medium\.com/[^\s")\']+')

CT_EXT = {
    "image/jpeg": "jpeg", "image/jpg": "jpeg", "image/png": "png",
    "image/gif": "gif", "image/webp": "webp", "image/svg+xml": "svg",
}

def detect_ext(url, content_type, data):
    if content_type:
        ct = content_type.split(";")[0].strip().lower()
        if ct in CT_EXT:
            return CT_EXT[ct]
    # magic-byte sniffing as a fallback
    if data[:3] == b"\xff\xd8\xff":
        return "jpeg"
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        return "png"
    if data[:6] in (b"GIF87a", b"GIF89a"):
        return "gif"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "webp"
    # last resort: extension already in the URL
    tail = url.rsplit("/", 1)[-1]
    if "." in tail:
        return tail.rsplit(".", 1)[-1].lower()
    return "jpg"

def slug_from_filename(fn):
    stem = os.path.splitext(os.path.basename(fn))[0]
    return re.sub(r"^\d{4}-\d{2}-\d{2}-", "", stem)  # strip leading date

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--posts", default="_posts")
    ap.add_argument("--assets", default="assets/img/medium")
    ap.add_argument("--prefix", default="/assets/img/medium")
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    if not os.path.isdir(a.posts):
        sys.exit(f"Posts folder not found: {a.posts}  (run this from your repo root)")
    if not a.dry_run:
        os.makedirs(a.assets, exist_ok=True)

    total_imgs = total_files = 0
    for fn in sorted(os.listdir(a.posts)):
        if not fn.endswith(".md"):
            continue
        path = os.path.join(a.posts, fn)
        text = open(path, encoding="utf-8").read()
        urls = []
        for u in URL_RE.findall(text):
            if u not in urls:
                urls.append(u)
        if not urls:
            continue
        slug = slug_from_filename(fn)
        changed = False
        for i, url in enumerate(urls, 1):
            base = f"{slug}-{i}"
            print(f"  [{fn}] image {i}: {url}")
            if a.dry_run:
                continue
            try:
                req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
                with urllib.request.urlopen(req, timeout=60) as r:
                    data = r.read()
                    ct = r.headers.get("Content-Type", "")
            except Exception as e:
                print(f"      !! download failed: {e}")
                continue
            ext = detect_ext(url, ct, data)
            out_name = f"{base}.{ext}"
            with open(os.path.join(a.assets, out_name), "wb") as f:
                f.write(data)
            text = text.replace(url, f"{a.prefix}/{out_name}")
            changed = True
            total_imgs += 1
            print(f"      -> {a.assets}/{out_name}")
        if changed and not a.dry_run:
            open(path, "w", encoding="utf-8").write(text)
            total_files += 1
    print(f"\nDone. Downloaded {total_imgs} images, updated {total_files} posts.")
    if a.dry_run:
        print("(dry run — nothing was written)")

if __name__ == "__main__":
    main()
