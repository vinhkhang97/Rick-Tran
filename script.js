const pipContainer = document.getElementById('pip-container');
const docPipButton = document.getElementById('doc-pip-button');

let pipWindow;

docPipButton.addEventListener('click', async () => {
  if (pipWindow) {
    // If a PiP window is already open, close it
    pipWindow.close();
    return;
  }

  try {
    // Request a new Picture-in-Picture window
    pipWindow = await window.documentPictureInPicture.requestWindow({
      width: 300,
      height: 400,
    });

    // Move the content to the new window
    pipWindow.document.body.append(pipContainer);

    // Copy stylesheets to the new window
    for (const sheet of document.styleSheets) {
      if (sheet.href) {
        const link = document.createElement('link');
        link.rel = 'stylesheet';
        link.href = sheet.href;
        pipWindow.document.head.appendChild(link);
      } else {
        const style = document.createElement('style');
        style.textContent = Array.from(sheet.cssRules)
          .map((rule) => rule.cssText)
          .join('');
        pipWindow.document.head.appendChild(style);
      }
    }

    // When the PiP window is closed, move the content back
    pipWindow.addEventListener('pagehide', () => {
      document.body.insertBefore(pipContainer, docPipButton);
      pipWindow = null;
    });
  } catch (error) {
    console.error('Error opening Document Picture-in-Picture window:', error);
  }
});
