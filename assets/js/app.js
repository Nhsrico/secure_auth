// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

/*
//from chatgpt
let AutofillFix = {
  mounted() {
    const inputs = this.el.querySelectorAll("input");
    inputs.forEach((input) => {
      // Trigger input event so LiveView tracks browser-filled values
      input.dispatchEvent(new Event("input", { bubbles: true }));
    });
  }
};
//End addition from chatgpt
*/

// Custom hooks for 2FA functionality
const Hooks = {
  AutofillFix: AutofillFix, //Rico from chatgpt
  QRCode: {
    mounted() {
      const qrText = this.el.dataset.qrText;
      if (qrText) {
        this.generateQRCode(qrText);
      }
    },

    generateQRCode(text) {
      // Create a more professional QR code placeholder
      const container = document.createElement("div");
      container.className = "flex flex-col items-center space-y-3";

      // QR Code placeholder
      const qrBox = document.createElement("div");
      qrBox.className =
        "w-48 h-48 bg-white border-2 border-gray-300 rounded-lg flex items-center justify-center";
      qrBox.innerHTML = `
          <div class="text-center">
            <div class="w-32 h-32 bg-gray-100 border border-gray-300 rounded mb-2 flex items-center justify-center">
              <div class="grid grid-cols-8 gap-0.5">
                ${Array.from(
                  { length: 64 },
                  (_, i) =>
                    `<div class="w-1 h-1 ${(i + Math.floor(i / 8)) % 2 === 0 ? "bg-gray-800" : "bg-gray-200"} rounded-sm"></div>`,
                ).join("")}
              </div>
            </div>
            <p class="text-xs text-gray-500">QR Code</p>
          </div>
        `;

      // Instructions
      const instructions = document.createElement("div");
      instructions.className = "text-center text-sm text-gray-600";
      instructions.innerHTML = `
          <p class="font-medium">Scan with your authenticator app:</p>
          <div class="mt-1 space-y-0.5">
            <p>• Google Authenticator</p>
            <p>• Authy</p>
            <p>• Microsoft Authenticator</p>
          </div>
        `;

      container.appendChild(qrBox);
      container.appendChild(instructions);
      this.el.appendChild(container);
    },
  },
};

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks: Hooks,
});

// Download functionality for backup codes
// Copy to clipboard functionality for API keys
window.addEventListener("phx:copy_to_clipboard", (event) => {
  const { text } = event.detail;
  navigator.clipboard
    .writeText(text)
    .then(() => {
      console.log("Text copied to clipboard");
    })
    .catch((err) => {
      console.error("Failed to copy text: ", err);
      // Fallback for older browsers
      const textArea = document.createElement("textarea");
      textArea.value = text;
      document.body.appendChild(textArea);
      textArea.select();
      document.execCommand("copy");
      document.body.removeChild(textArea);
    });
});

window.addEventListener("phx:download", (event) => {
  const { filename, content, content_type } = event.detail;
  const blob = new Blob([content], { type: content_type });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener(
    "phx:live_reload:attached",
    ({ detail: reloader }) => {
      // Enable server log streaming to client.
      // Disable with reloader.disableServerLogs()
      reloader.enableServerLogs();

      // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
      //
      //   * click with "c" key pressed to open at caller location
      //   * click with "d" key pressed to open at function component definition location
      let keyDown;
      window.addEventListener("keydown", (e) => (keyDown = e.key));
      window.addEventListener("keyup", (e) => (keyDown = null));
      window.addEventListener(
        "click",
        (e) => {
          if (keyDown === "c") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtCaller(e.target);
          } else if (keyDown === "d") {
            e.preventDefault();
            e.stopImmediatePropagation();
            reloader.openEditorAtDef(e.target);
          }
        },
        true,
      );

      window.liveReloader = reloader;
    },
  );
}
