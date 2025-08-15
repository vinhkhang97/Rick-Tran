const video = document.getElementById("video");
const pipButton = document.getElementById("pip-button");
const log = document.getElementById("log");

if (document.pictureInPictureEnabled) {
  pipButton.removeAttribute("disabled");
} else {
  log.innerText = "PiP not supported. Check browser compatibility for details.";
}

function togglePictureInPicture() {
  if (document.pictureInPictureElement) {
    document.exitPictureInPicture();
  } else {
    video.requestPictureInPicture();
  }
}

pipButton.addEventListener("click", togglePictureInPicture);

// Add event listeners to add/remove a class for styling
video.addEventListener('enterpictureinpicture', () => {
  video.classList.add('in-pip');
});

video.addEventListener('leavepictureinpicture', () => {
  video.classList.remove('in-pip');
});
