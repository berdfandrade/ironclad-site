// Runs in <head> so the theme is set before the first paint.
(function () {
  var root = document.documentElement, saved;
  try { saved = localStorage.getItem("theme"); } catch (e) {}
  if (saved !== "light" && saved !== "dark") {
    saved = matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark";
  }
  root.dataset.theme = saved;

  document.addEventListener("DOMContentLoaded", function () {
    var button = document.getElementById("theme-toggle");
    if (!button) return;
    function label() {
      var next = root.dataset.theme === "light" ? "dark" : "light";
      button.setAttribute("aria-label", "Switch to " + next + " theme");
      button.title = "Switch to " + next + " theme";
    }
    button.hidden = false;
    label();
    button.addEventListener("click", function () {
      root.dataset.theme = root.dataset.theme === "light" ? "dark" : "light";
      try { localStorage.setItem("theme", root.dataset.theme); } catch (e) {}
      label();
    });
  });
})();
