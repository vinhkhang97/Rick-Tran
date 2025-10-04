import http.server
import json
import subprocess
import os
import ssl
import glob
import time
import pty
import fcntl
import select
import atexit
import secrets
import socket

PORT = 8000
# Make the server location-independent by using the script's own directory
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CERTFILE = os.path.join(SCRIPT_DIR, 'server.pem')

# --- PTY Setup ---
# Create a pseudo-terminal
master_fd, slave_fd = pty.openpty()

# Start an interactive csh process in the pseudo-terminal
pty_process = subprocess.Popen(
    ['csh', '-i'],
    preexec_fn=os.setsid,
    stdin=slave_fd,
    stdout=slave_fd,
    stderr=slave_fd,
    close_fds=True,
    env=os.environ
)

# --- Process Cleanup ---
# Ensure the PTY process is killed when the server exits
def cleanup_pty_process():
    print("Server shutting down. Terminating PTY process.")
    if pty_process.poll() is None:
        pty_process.terminate()
        try:
            pty_process.wait(timeout=2)
        except subprocess.TimeoutExpired:
            pty_process.kill()
    print("PTY process terminated.")

atexit.register(cleanup_pty_process)


# Make the master file descriptor non-blocking for reading
fl = fcntl.fcntl(master_fd, fcntl.F_GETFL)
fcntl.fcntl(master_fd, fcntl.F_SETFL, fl | os.O_NONBLOCK)

def read_all_from_pty(fd, timeout=0.2):
    """Reads available output from a file descriptor with a timeout."""
    time.sleep(timeout)
    output_buffer = b""
    while True:
        ready, _, _ = select.select([fd], [], [], 0)
        if not ready:
            break
        try:
            chunk = os.read(fd, 8192)
            if not chunk: # PTY was closed
                break
            output_buffer += chunk
        except BlockingIOError:
            break
    return output_buffer.decode(errors='ignore')

# Read and discard the initial shell prompt/greeting to clear the buffer
initial_output = read_all_from_pty(master_fd, timeout=0.5)
print(f"--- Initial Shell Output (Discarded) ---\n{initial_output.strip()}\n--------------------------------------")


class InteractiveHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    """
    A stateful, secure request handler using a persistent PTY session
    for true interactivity. The CWD is now managed dynamically via the PTY.
    """
    os.write(master_fd, b'pwd\n')
    cwd_output = read_all_from_pty(master_fd)
    cwd_lines = [line.strip() for line in cwd_output.strip().split('\n') if line.strip()]
    cwd = cwd_lines[-2] if len(cwd_lines) > 1 else os.path.expanduser('~')
    is_interactive_session = False # This will track the state of the session
    print(f"Initial CWD detected as: {cwd}")


    def do_POST(self):
        if self.path == '/command':
            self.handle_command()
        elif self.path == '/complete':
            self.handle_completion()
        elif self.path == '/in-tool-complete':
            self.handle_in_tool_completion()
        else:
            self.send_error(404, "Not Found")

    def handle_in_tool_completion(self):
        try:
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data)
            text_to_complete = data.get('text', '')
            os.write(master_fd, (text_to_complete + '\t').encode())
            completed_output = read_all_from_pty(master_fd, timeout=0.3)
            response = {'completed_text': completed_output.strip()}
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode('utf-8'))
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response_data = {'output': f"Server Error: {e}"}
            self.wfile.write(json.dumps(response_data).encode('utf-8'))

    def handle_command(self):
        try:
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data)
            command = data.get('command', '').strip()

            # --- The Final, Correct, Stateful Logic ---
            if command == 'exit_interactive_mode':
                os.write(master_fd, b'\x03') # Send Ctrl+C to kill the foreground process
                # Run 'stty sane' to reset the terminal to a known-good state.
                os.write(master_fd, b'stty sane\n')
                InteractiveHTTPRequestHandler.is_interactive_session = False
                read_all_from_pty(master_fd, timeout=0.2) # Clear any output
                output = "Forcibly exited interactive mode. Returned to main shell."
                response = {'output': output, 'cwd': self.cwd, 'interactive': False}
            elif InteractiveHTTPRequestHandler.is_interactive_session:
                if pty_process.poll() is not None:
                    InteractiveHTTPRequestHandler.is_interactive_session = False
                    output = "\nInteractive process has terminated. Returning to main shell."
                    response = {'output': output, 'cwd': self.cwd, 'interactive': False}
                else:
                    os.write(master_fd, (command + '\n').encode())
                    output = read_all_from_pty(master_fd, timeout=0.5)
                    response = {'output': output, 'cwd': self.cwd, 'interactive': True}
            else:
                os.write(master_fd, b'stty -echo\n')
                read_all_from_pty(master_fd, timeout=0.1)
                BOUNDARY_MARKER = f"---JULES-BOUNDARY-{secrets.token_hex(16)}---"
                PWD_MARKER = f"---JULES-PWD-{secrets.token_hex(16)}---"
                pty_command = f"{command}; echo '{BOUNDARY_MARKER}'; pwd; echo '{PWD_MARKER}'\n"
                os.write(master_fd, pty_command.encode())
                output_buffer = ""
                timeout_seconds = 20
                start_time = time.time()
                while PWD_MARKER not in output_buffer and (time.time() - start_time) < timeout_seconds:
                    ready, _, _ = select.select([master_fd], [], [], 0.1)
                    if ready:
                        try:
                            chunk = os.read(master_fd, 8192).decode(errors='ignore')
                            if chunk: output_buffer += chunk
                            else: break
                        except BlockingIOError: pass
                os.write(master_fd, b'stty echo\n')
                read_all_from_pty(master_fd, timeout=0.1)
                if BOUNDARY_MARKER in output_buffer and PWD_MARKER in output_buffer:
                    main_output, rest = output_buffer.split(BOUNDARY_MARKER, 1)
                    pwd_output, _ = rest.split(PWD_MARKER, 1)
                    output = main_output.strip()
                    cwd_lines = [line.strip() for line in pwd_output.strip().split('\n') if line.strip()]
                    if cwd_lines:
                        new_cwd = cwd_lines[-1]
                        if os.path.isdir(new_cwd): InteractiveHTTPRequestHandler.cwd = new_cwd
                    response = {'output': output, 'cwd': self.cwd, 'interactive': False}
                else:
                    output = output_buffer.strip()
                    InteractiveHTTPRequestHandler.is_interactive_session = True
                    response = {'output': output, 'cwd': self.cwd, 'interactive': True}

            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode('utf-8'))
        except Exception as e:
            self.send_response(500)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response_data = {'output': f"Server Error: {e}", 'cwd': self.cwd, 'interactive': False}
            self.wfile.write(json.dumps(response_data).encode('utf-8'))

    def handle_completion(self):
        try:
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data)
            text_to_complete = data.get('text', '')
            current_arg = text_to_complete.split(' ')[-1]
            if not current_arg:
                self.send_completions([])
                return
            if current_arg.startswith('~'):
                path_pattern = os.path.expanduser(current_arg) + '*'
            else:
                path_pattern = os.path.join(InteractiveHTTPRequestHandler.cwd, current_arg) + '*'
            matches = glob.glob(path_pattern)
            completions = [os.path.basename(m) + ('/' if os.path.isdir(m) else '') for m in matches]
            self.send_completions(completions)
        except Exception:
            self.send_completions([])

    def send_completions(self, completions):
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({'completions': completions}).encode('utf-8'))

    def do_GET(self):
        if self.path == '/':
            self.path = 'index.html'
        return http.server.SimpleHTTPRequestHandler.do_GET(self)

def run_server():
    os.chdir(SCRIPT_DIR)
    if not os.path.exists(CERTFILE):
        print(f"Generating certificate '{CERTFILE}'...")
        subprocess.run(['openssl', 'req', '-new', '-x509', '-keyout', CERTFILE, '-out', CERTFILE, '-days', '365', '-nodes', '-subj', '/C=US/ST=CA/L=SF/O=Org/CN=localhost'])
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(certfile=CERTFILE)
    hostname = socket.gethostname()
    with http.server.HTTPServer(("", PORT), InteractiveHTTPRequestHandler) as httpd:
        httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
        print(f"Serving HTTPS web console at https://{hostname}:{PORT}")
        print(f"Initial directory: {InteractiveHTTPRequestHandler.cwd}")
        httpd.serve_forever()

if __name__ == '__main__':
    try:
        run_server()
    except Exception as e:
        import traceback
        with open("server_crash.log", "w") as f:
            f.write(f"Server crashed unexpectedly:\n{e}\n")
            f.write(traceback.format_exc())