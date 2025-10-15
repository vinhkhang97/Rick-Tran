#!/home/t_FXW1AA001A_PR/Environment/script/python/Python-3.8.9/bin/python3.8
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
import shutil

PORT = 8000
# Make the server location-independent by using the script's own directory
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
CERTFILE = os.path.join(SCRIPT_DIR, 'server.pem')

# --- PTY Setup ---
master_fd, slave_fd = pty.openpty()

# Find an available shell
def find_shell():
    for shell in ['csh', 'bash', 'sh']:
        path = shutil.which(shell)
        if path:
            return path
    return None

shell_path = find_shell()
if not shell_path:
    print("Error: Could not find a suitable shell (csh, bash, or sh).")
    exit(1)

pty_process = subprocess.Popen(
    [shell_path, '-i'],
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
    # Initialize class variables
    os.write(master_fd, b'pwd\n')
    cwd_output = read_all_from_pty(master_fd)
    cwd_lines = [line.strip() for line in cwd_output.strip().split('\n') if line.strip()]
    # A simple heuristic to get the last non-empty line which should be the CWD
    cwd = cwd_lines[-1] if cwd_lines else os.path.expanduser('~')
    is_interactive_session = False # This will track the state of the session
    print(f"Initial CWD detected as: {cwd}")


    def do_POST(self):
        if self.path == '/command':
            self.handle_command()
        elif self.path == '/complete':
            self.handle_completion()
        elif self.path == '/in-tool-complete':
            self.handle_in_tool_completion()
        elif self.path == '/kill-command':
            self.handle_kill_command()
        else:
            self.send_error(404, "Not Found")

    def handle_in_tool_completion(self):
        try:
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data)
            text_to_complete = data.get('text', '')
            # Pass the current input text and a tab character to the interactive tool
            os.write(master_fd, (text_to_complete + '\t').encode())
            # Read the PTY's response, which should be the completed text
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

    def _parse_interactive_output(self, output_str):
        """
        Parses the output of an interactive command.
        Returns a tuple of (content, prompt).
        Heuristic: Last non-empty line is the prompt.
        """
        output_str = output_str.strip()
        lines = output_str.split('\n')
        
        if not lines:
            return "", "> "
            
        last_line_index = -1
        for i in range(len(lines) - 1, -1, -1):
            if lines[i].strip():
                last_line_index = i
                break
        
        if last_line_index == -1:
            return "", "> "

        prompt = lines[last_line_index].strip()
        content = '\n'.join(lines[:last_line_index]).strip()
        
        return content, prompt

    def handle_kill_command(self):
        """Sends a Ctrl+C signal to the PTY to kill the foreground process."""
        try:
            os.write(master_fd, b'\x03') # Ctrl+C
            # Reset terminal state after killing a process
            os.write(master_fd, b'stty sane\n')
            InteractiveHTTPRequestHandler.is_interactive_session = False
            # Read any output from the killed command
            output = read_all_from_pty(master_fd, timeout=0.2)
            output += "\n[Process terminated with Ctrl+C]"
            
            response = {'output': output, 'cwd': self.cwd, 'interactive': False}
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode('utf-8'))
        except Exception as e:
            self.send_error(500, f"Server Error: {e}")

    def handle_command(self):
        try:
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data)
            command = data.get('command', '').strip()
            
            # Special command from frontend to get out of a stuck process like vim
            if command == 'exit_stuck_command':
                os.write(master_fd, b'\x03') # Send Ctrl+C
                os.write(master_fd, b'stty sane\n') # Reset terminal
                InteractiveHTTPRequestHandler.is_interactive_session = False
                read_all_from_pty(master_fd, timeout=0.2) # Clear buffer
                output = "Forcibly exited interactive mode."
                response = {'output': output, 'cwd': self.cwd, 'interactive': False, 'interactive_prompt': None}
            # If we are in an interactive session, just pass the command through
            elif InteractiveHTTPRequestHandler.is_interactive_session:
                if pty_process.poll() is not None: # Check if the process died
                    InteractiveHTTPRequestHandler.is_interactive_session = False
                    output = "\nInteractive process terminated."
                    response = {'output': output, 'cwd': self.cwd, 'interactive': False, 'interactive_prompt': None}
                else:
                    os.write(master_fd, (command + '\n').encode())
                    raw_output = read_all_from_pty(master_fd, timeout=0.5)
                    output, new_prompt = self._parse_interactive_output(raw_output)
                    response = {'output': output, 'cwd': self.cwd, 'interactive': True, 'interactive_prompt': new_prompt}
            # Otherwise, use the boundary markers for normal commands
            else:
                # Disable echo to prevent the command from being duplicated in the output
                os.write(master_fd, b'stty -echo\n')
                read_all_from_pty(master_fd, timeout=0.1)

                BOUNDARY_MARKER = f"---JULES-BOUNDARY-{secrets.token_hex(16)}---"
                PWD_MARKER = f"---JULES-PWD-{secrets.token_hex(16)}---"
                
                # Wrap the command with markers
                pty_command = f"{command}; echo '{BOUNDARY_MARKER}'; pwd; echo '{PWD_MARKER}'\n"
                os.write(master_fd, pty_command.encode())
                
                output_buffer = ""
                timeout_seconds = 20
                start_time = time.time()
                
                # Read until the final marker is seen or timeout
                while PWD_MARKER not in output_buffer and (time.time() - start_time) < timeout_seconds:
                    ready, _, _ = select.select([master_fd], [], [], 0.1)
                    if ready:
                        try:
                            chunk = os.read(master_fd, 8192).decode(errors='ignore')
                            if chunk:
                                output_buffer += chunk
                            else: # PTY closed
                                break 
                        except BlockingIOError:
                            pass # No data available right now, loop again

                # Re-enable echo
                os.write(master_fd, b'stty echo\n')
                read_all_from_pty(master_fd, timeout=0.1)

                # Check if we got the expected markers back
                if BOUNDARY_MARKER in output_buffer and PWD_MARKER in output_buffer:
                    main_output, rest = output_buffer.split(BOUNDARY_MARKER, 1)
                    pwd_output, _ = rest.split(PWD_MARKER, 1)
                    
                    output = main_output.strip()
                    cwd_lines = [line.strip() for line in pwd_output.strip().split('\n') if line.strip()]
                    if cwd_lines:
                        new_cwd = cwd_lines[-1]
                        # Basic validation for the new CWD
                        if os.path.isdir(new_cwd):
                             InteractiveHTTPRequestHandler.cwd = new_cwd
                    
                    response = {'output': output, 'cwd': self.cwd, 'interactive': False, 'interactive_prompt': None}
                else: # No markers found, assume it's an interactive session (e.g., vim, innovus)
                    raw_output = output_buffer.strip()
                    InteractiveHTTPRequestHandler.is_interactive_session = True
                    output, new_prompt = self._parse_interactive_output(raw_output)
                    response = {'output': output, 'cwd': self.cwd, 'interactive': True, 'interactive_prompt': new_prompt}

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

            # This is a robust file/directory completion.
            current_arg = text_to_complete.split(' ')[-1]
            if not current_arg:
                self.send_completions([])
                return

            # Handle home directory expansion
            if current_arg.startswith('~'):
                path_pattern = os.path.expanduser(current_arg) + '*'
            else:
                # Build a path relative to the current working directory
                path_pattern = os.path.join(InteractiveHTTPRequestHandler.cwd, current_arg) + '*'
            
            # Use glob to find matches
            matches = glob.glob(path_pattern)
            
            # Format completions to be just the file/dir name
            completions = []
            for match in matches:
                completion = os.path.basename(match)
                if os.path.isdir(match):
                    completion += '/'
                completions.append(completion)

            self.send_completions(completions)
        except Exception as e:
            print(f"Completion error: {e}")
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
    # Change to the script's directory to serve files correctly
    os.chdir(SCRIPT_DIR)
    
    if not os.path.exists(CERTFILE):
        print(f"Generating certificate '{CERTFILE}'...")
        subprocess.run(['openssl', 'req', '-new', '-x509', '-keyout', CERTFILE, '-out', CERTFILE, '-days', '365', '-nodes', '-subj', '/C=US/ST=CA/L=SF/O=Org/CN=localhost'])
    
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(certfile=CERTFILE)
    
    # Determine hostname for the welcome message
    def get_local_ip():
        """Finds the local IP address of the machine."""
        s = None
        try:
            # This is a trick to find the primary outbound IP address.
            # It doesn't actually send any data.
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(('8.8.8.8', 1))
            ip = s.getsockname()[0]
        except Exception:
            ip = '127.0.0.1' # Fallback to loopback address
        finally:
            if s:
                s.close()
        return ip

    hostname = get_local_ip()
    
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
        # Log crashes to a file for easier debugging
        with open("server_crash.log", "w") as f:
            f.write(f"Server crashed unexpectedly:\n{e}\n")
            f.write(traceback.format_exc())
