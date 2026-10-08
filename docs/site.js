(function () {
  var root = document.documentElement;
  var choices = Array.prototype.slice.call(document.querySelectorAll("[data-theme-choice]"));

  function setTheme(name, focus) {
    root.dataset.theme = name;
    choices.forEach(function (button) {
      var on = button.dataset.themeChoice === name;
      button.setAttribute("aria-checked", on ? "true" : "false");
      button.tabIndex = on ? 0 : -1;
      if (on && focus) button.focus();
    });
    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute("content", getComputedStyle(root).getPropertyValue("--bg").trim());
    try { localStorage.setItem("podtune-theme", name); } catch (e) {}
    syncDemo();
  }

  // The demo follows the page theme, and phones get a crop of the voice test half.
  var video = document.getElementById("demo");
  var phone = window.matchMedia ? window.matchMedia("(max-width: 560px)") : null;
  function reducedMotion() {
    return !!(window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches);
  }
  function demoFor(name) {
    var suffix = phone && phone.matches ? "-mobile" : "";
    return { src: "assets/demo/demo-" + name + suffix + ".mp4", poster: "assets/demo/poster-" + name + suffix + ".webp" };
  }
  function syncDemo() {
    if (!video) return;
    var next = demoFor(root.dataset.theme || "dark");
    if (video.getAttribute("src") === next.src) return;
    var first = !video.getAttribute("src");
    var time = video.currentTime || 0;
    var playing = first ? !reducedMotion() : !video.paused;
    video.poster = next.poster;
    video.src = next.src;
    video.addEventListener("loadedmetadata", function restore() {
      video.removeEventListener("loadedmetadata", restore);
      if (time > 0 && time < video.duration) video.currentTime = time;
      if (playing) { var attempt = video.play(); if (attempt && attempt.catch) attempt.catch(function () {}); }
    });
  }

  choices.forEach(function (button, index) {
    button.addEventListener("click", function () { setTheme(button.dataset.themeChoice, false); });
    button.addEventListener("keydown", function (event) {
      var step = event.key === "ArrowRight" || event.key === "ArrowDown" ? 1 : event.key === "ArrowLeft" || event.key === "ArrowUp" ? -1 : 0;
      if (!step) return;
      event.preventDefault();
      var next = choices[(index + step + choices.length) % choices.length];
      setTheme(next.dataset.themeChoice, true);
    });
  });
  setTheme(root.dataset.theme || "dark", false);

  // The demo plays muted on a loop. Reduced motion keeps it paused until the visitor starts it.
  var toggle = document.querySelector(".demo-toggle");
  if (phone && phone.addEventListener) phone.addEventListener("change", syncDemo);
  function syncToggle() {
    var paused = video.paused;
    toggle.dataset.paused = paused ? "true" : "false";
    toggle.querySelector(".toggle-label").textContent = paused ? "Play" : "Pause";
  }
  if (video && toggle) {
    video.addEventListener("play", syncToggle);
    video.addEventListener("pause", syncToggle);
    toggle.addEventListener("click", function () { if (video.paused) video.play(); else video.pause(); });
    syncToggle();
  }

  // Copy buttons for the install commands.
  Array.prototype.forEach.call(document.querySelectorAll(".copy"), function (button) {
    button.addEventListener("click", function () {
      var text = button.parentElement.querySelector("code").textContent;
      var done = function () {
        button.textContent = "Copied";
        button.setAttribute("data-copied", "");
        setTimeout(function () { button.textContent = "Copy"; button.removeAttribute("data-copied"); }, 1600);
      };
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(done, function () { button.textContent = "Select the text"; });
      } else {
        button.textContent = "Select the text";
      }
    });
  });
})();
