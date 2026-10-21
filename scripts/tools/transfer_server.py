# Servidor local SOLO para desarrollo: pasa modelos entre ventanas de Roblox Studio
# y sirve los scripts de la carpeta scripts/.
#   POST /drop/<nombre>  -> guarda el cuerpo (texto base64) en drop/<nombre>
#   GET  /<ruta>         -> devuelve el archivo (scripts o drop/)
# Escucha solo en 127.0.0.1 (no es accesible desde otra computadora).
import os
import sys
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # carpeta scripts/
DROP = os.path.join(ROOT, "tools", "drop")
os.makedirs(DROP, exist_ok=True)


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def do_POST(self):
        if not self.path.startswith("/drop/"):
            self.send_error(404)
            return
        name = os.path.basename(self.path[len("/drop/"):].split("?")[0])
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        with open(os.path.join(DROP, name), "wb") as f:
            f.write(body)
        self.send_response(200)
        self.end_headers()
        self.wfile.write(f"saved {name} {len(body)}".encode())

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 34999
    ThreadingHTTPServer(("127.0.0.1", port), Handler).serve_forever()
