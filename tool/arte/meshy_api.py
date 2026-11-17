"""Cliente mínimo de la API de Meshy (imágenes 2D). La clave sale de
MESHY_API_KEY y nunca se imprime ni se escribe en disco.

Uso:
  meshy.py balance
  meshy.py create OUT_DIR NAME '{"json": "body"}' ENDPOINT   -> crea, espera y descarga
  meshy.py get ENDPOINT TASK_ID
"""
import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request

API = "https://api.meshy.ai/openapi/v1"


def _req(method, path, body=None):
    key = os.environ.get("MESHY_API_KEY")
    if not key:
        sys.exit("MESHY_API_KEY no definida")
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(API + path, data=data, method=method)
    r.add_header("Authorization", "Bearer " + key)
    r.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(r, timeout=120) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        msg = e.read().decode(errors="replace")[:500]
        sys.exit(f"HTTP {e.code} en {method} {path}: {msg}")


def data_uri(path):
    ext = os.path.splitext(path)[1].lower().lstrip(".")
    mime = {"jpg": "jpeg", "jpeg": "jpeg", "png": "png", "webp": "webp"}[ext]
    with open(path, "rb") as f:
        return f"data:image/{mime};base64," + base64.b64encode(f.read()).decode()


def wait(endpoint, task_id, timeout=900):
    start = time.time()
    while True:
        t = _req("GET", f"/{endpoint}/{task_id}")
        st = t.get("status")
        if st in ("SUCCEEDED", "FAILED", "CANCELED"):
            return t
        if time.time() - start > timeout:
            sys.exit(f"Tiempo agotado esperando {task_id} (sigue en el servidor)")
        time.sleep(5)


def download(url, out):
    with urllib.request.urlopen(url, timeout=120) as resp, open(out, "wb") as f:
        f.write(resp.read())


def main():
    cmd = sys.argv[1]
    if cmd == "balance":
        print(json.dumps(_req("GET", "/balance")))
        return
    if cmd == "get":
        t = _req("GET", f"/{sys.argv[2]}/{sys.argv[3]}")
        t.pop("image_urls", None)
        print(json.dumps(t))
        return
    if cmd == "create":
        out_dir, name, body_json, endpoint = sys.argv[2:6]
        body = json.loads(body_json)
        # Rutas locales -> data URI.
        refs = body.get("reference_image_urls")
        if refs:
            body["reference_image_urls"] = [data_uri(p) if os.path.exists(p) else p for p in refs]
        os.makedirs(out_dir, exist_ok=True)
        task_id = _req("POST", f"/{endpoint}", body)["result"]
        print(json.dumps({"name": name, "task_id": task_id, "status": "submitted"}), flush=True)
        t = wait(endpoint, task_id)
        files = []
        for i, url in enumerate(t.get("image_urls") or []):
            ext = ".png" if body.get("remove_background") or ".png" in url.split("?")[0] else ".jpg"
            out = os.path.join(out_dir, f"{name}{'' if i == 0 else '-' + str(i)}{ext}")
            download(url, out)
            files.append(out)
        print(json.dumps({
            "name": name, "task_id": task_id, "status": t.get("status"),
            "consumed_credits": t.get("consumed_credits"), "error": t.get("task_error"),
            "files": files,
        }), flush=True)
        return
    sys.exit("comando desconocido")


if __name__ == "__main__":
    main()
