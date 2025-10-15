document.addEventListener('DOMContentLoaded', () => {
    const output = document.getElementById('output');
    const commandInput = document.getElementById('command-input');
    const prompt = document.getElementById('prompt');
    let cwd = '~';
    let commandHistory = [];
    let historyIndex = -1;
    let lastCompletionText = null;
    let lastCompletions = [];
    let isInteractive = false;
    let interactivePrompt = null; // Will hold the prompt from the interactive tool

    const updatePrompt = () => {
        prompt.style.display = 'inline'; // Always show the prompt
        if (isInteractive && interactivePrompt) {
            prompt.textContent = interactivePrompt; // e.g., "innovus 1> "
        } else if (isInteractive) {
            prompt.textContent = '> '; // Fallback for interactive sessions
        } else {
            prompt.textContent = `[${cwd}]$ `; // Main shell prompt
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
        const promptForHistory = prompt.textContent;

        if (command.trim() !== '') {
            output.innerHTML += `<div class="command-entry"><span class="prompt">${escapeHtml(promptForHistory)}</span>${escapeHtml(command)}</div>`;
            if (data.output) {
                output.innerHTML += `<div class="output-entry">${escapeHtml(data.output)}</div>`;
            }
        }

        cwd = data.cwd;
        isInteractive = data.interactive;
        interactivePrompt = data.interactive_prompt;
        
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
            .replace(/'/g, "&#39;");
    };

    // Set initial CWD and prompt
    executeCommand('');

    // --- Picture-in-Picture Logic ---
    const pipButton = document.getElementById('pip-button');
    const terminalContainer = document.getElementById('terminal');
    const mainBody = document.body;

    if ('documentPictureInPicture' in window) {
        pipButton.addEventListener('click', async () => {
            try {
                const pipWindow = await window.documentPictureInPicture.requestWindow({
                    width: terminalContainer.clientWidth,
                    height: terminalContainer.clientHeight,
                });

                // Copy stylesheets to the new window
                [...document.styleSheets].forEach((styleSheet) => {
                    try {
                        const cssRules = [...styleSheet.cssRules].map((rule) => rule.cssText).join('');
                        const style = document.createElement('style');
                        style.textContent = cssRules;
                        pipWindow.document.head.appendChild(style);
                    } catch (e) {
                        const link = document.createElement('link');
                        link.rel = 'stylesheet';
                        link.type = styleSheet.type;
                        link.href = styleSheet.href;
                        pipWindow.document.head.appendChild(link);
                    }
                });

                // Move the terminal to the new window
                pipWindow.document.body.append(terminalContainer);

                // When the PiP window is closed, move the terminal back
                pipWindow.addEventListener('pagehide', () => {
                    mainBody.append(terminalContainer);
                });

            } catch (error) {
                console.error('Failed to enter Picture-in-Picture mode:', error);
            }
        });
    } else {
        // If the API is not supported, disable the button and inform the user.
        pipButton.disabled = true;
        pipButton.title = 'Document Picture-in-Picture is not supported by your browser';
        pipButton.style.cursor = 'not-allowed';
        pipButton.style.opacity = '0.5';
        console.log('Document Picture-in-Picture API is not supported.');
    }
});
