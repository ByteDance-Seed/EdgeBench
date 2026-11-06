import http.server
import os
from datetime import datetime
import webbrowser
import urllib.request


# Define a handler class
class MyHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            # Serve a string constant at the index
            if self.path == "/":
                self.send_response(200)
                self.send_header("Content-type", "text/html")
                self.end_headers()
                with open("watch_trace.html", "rb") as file:
                    self.wfile.write(file.read())

            # Stream the contents of 'trace.json' at '/trace.json'
            elif self.path == "/trace.json":
                self.send_response(200)
                self.send_header("Content-type", "application/json")
                self.end_headers()
                with open("trace.json", "rb") as file:
                    while chunk := file.read(8192):
                        self.wfile.write(chunk)

            # Serve the file modification time of 'trace.json' at '/mtime'
            elif self.path == "/mtime":
                mtime = os.path.getmtime("trace.json")
                last_modified_date = datetime.fromtimestamp(mtime).strftime(
                    "%Y-%m-%d %H:%M:%S"
                )
                self.send_response(200)
                self.send_header("Content-type", "text/plain")
                self.end_headers()
                self.wfile.write(last_modified_date.encode())

            elif self.path.startswith("/perfetto"):
                proxy_url = "https://ui.perfetto.dev" + self.path[len("/perfetto") :]
                print("Proxying request to " + proxy_url)
                with urllib.request.urlopen(proxy_url) as response:
                    self.send_response(response.status)

                    self.end_headers()
                    res = response.read()
                    if self.path.endswith("frontend_bundle.js"):
                        print("Activating replacement")
                        # Fix a bug in Perfetto that they haven't deployed the fix for yet but have fixed internally
                        res = res.replace(
                            b"throw new Error(`EngineProxy ${this.tag} was disposed.`);",
                            b"return null;",
                        )
                        # Auto-expand tracks by default
                        res = res.replace(b"collapsed: true", b"collapsed: false")
                        res = res.replace(
                            b"collapsed: !hasHeapProfiles", b"collapsed: false"
                        )
                    for header in response.headers:
                        if header == "Content-Length":
                            self.send_header(header, len(res))
                        self.send_header(header, response.headers[header])
                    self.wfile.write(res)

            else:
                self.send_error(404, "File Not Found: {}".format(self.path))

        except IOError:
            self.send_error(404, "File Not Found: {}".format(self.path))


# Start the server
def run(server_class=http.server.HTTPServer, handler_class=MyHandler):
    server_address = ("", 8000)
    httpd = server_class(server_address, handler_class)
    print("Starting httpd...")
    webbrowser.open("http://localhost:8000")
    httpd.serve_forever()


# Run the server
if __name__ == "__main__":
    run()
