document.addEventListener('DOMContentLoaded', () => {
    const output = document.getElementById('output');
    const commandInput = document.getElementById('command-input');
    const prompt = document.getElementById('prompt');

    let cwd = '~';
    let commandHistory = [];
    let historyIndex = -1;
    let lastCompletionText = null;
    let lastCompletions = [];
    let isInteractive = false; // New state to track if a sub-shell is active

    // This function now shows or hides the prompt based on the interactive state
    const updatePrompt = () => {
        const promptContainer = document.getElementById('input-line');
        if (isInteractive) {
            // Hide the prompt container when in an interactive sub-shell
            prompt.style.display = 'none';
        } else {
            // Show the prompt container for the main shell
            prompt.style.display = 'inline';
            prompt.textContent = `[${cwd}]$ `;
        }
    };

    const executeCommand = async (command) => {
        if (command.trim() !== '') {
            commandHistory.unshift(command);
            historyIndex = -1;
        }

        const response = await fetch('/command', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ command: command })
        });

        const data = await response.json();
        
        // Use the prompt state *before* the command ran for the history display
        const promptForHistory = isInteractive ? '' : `[${cwd}]$ `;
        
        if (command.trim() !== '') {
            output.innerHTML += `<div class="command-entry"><span class="prompt">${escapeHtml(promptForHistory)}</span>${escapeHtml(command)}</div>`;
            if (data.output) {
                output.innerHTML += `<div class="output-entry">${escapeHtml(data.output)}</div>`;
            }
        }

        // Update state for the *next* prompt based on the server's response
        cwd = data.cwd;
        isInteractive = data.interactive;
        updatePrompt();
        output.scrollTop = output.scrollHeight;
    };

    const findCommonPrefix = (completions) => {
        if (!completions || completions.length === 0) return '';
        let prefix = completions[0];
        for (let i = 1; i < completions.length; i++) {
            while (completions[i].indexOf(prefix) !== 0) {
                prefix = prefix.substring(0, prefix.length - 1);
                if (prefix === '') return '';
            }
        }
        return prefix;
    };

    const handleAutocomplete = async () => {
        const currentInput = commandInput.value;

        if (isInteractive) {
            // --- In-Tool Tab Completion ---
            const response = await fetch('/in-tool-complete', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ text: currentInput })
            });
            const data = await response.json();
            if (data.completed_text) {
                commandInput.value = data.completed_text;
            }
        } else {
            // --- Standard Shell Completion ---
            const textToComplete = currentInput.split(' ').pop();
            if (currentInput === lastCompletionText && lastCompletions.length > 1) {
                output.innerHTML += `<div class="completions">${lastCompletions.join('&nbsp;&nbsp;')}</div>`;
                output.scrollTop = output.scrollHeight;
                lastCompletionText = null;
                lastCompletions = [];
                return;
            }

            const response = await fetch('/complete', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ text: textToComplete })
            });
            const data = await response.json();
            const completions = data.completions || [];

            lastCompletionText = currentInput;
            lastCompletions = completions;

            if (completions.length === 0) return;

            if (completions.length === 1) {
                const parts = currentInput.split(' ');
                parts.pop();
                parts.push(completions[0]);
                commandInput.value = parts.join(' ');
                lastCompletionText = null;
                lastCompletions = [];
            } else {
                const prefix = findCommonPrefix(completions);
                const currentArg = currentInput.split(' ').pop();
                if (prefix && prefix.length > currentArg.length) {
                    const parts = currentInput.split(' ');
                    parts.pop();
                    parts.push(prefix);
                    commandInput.value = parts.join(' ');
                    lastCompletionText = commandInput.value;
                }
            }
        }
    };

    commandInput.addEventListener('keydown', async (e) => {
        if (e.key !== 'Tab') {
            lastCompletionText = null;
            lastCompletions = [];
        }

        if (e.key === 'Enter') {
            await executeCommand(commandInput.value);
            commandInput.value = '';
        } else if (e.key === 'ArrowUp') {
            e.preventDefault();
            if (historyIndex < commandHistory.length - 1) {
                historyIndex++;
                commandInput.value = commandHistory[historyIndex];
            }
        } else if (e.key === 'ArrowDown') {
            e.preventDefault();
            if (historyIndex > 0) {
                historyIndex--;
                commandInput.value = commandHistory[historyIndex];
            } else {
                historyIndex = -1;
                commandInput.value = '';
            }
        } else if (e.key === 'Tab') {
            e.preventDefault();
            await handleAutocomplete();
        }
    });

    const escapeHtml = (text) => {
        if (typeof text !== 'string') return '';
        return text
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    };

    // Set initial CWD and prompt by sending a harmless empty command
    executeCommand('');
});
