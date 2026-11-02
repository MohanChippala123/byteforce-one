(function () {
  if (location.protocol === "file:" || location.hostname === "localhost" || location.hostname === "127.0.0.1") {
    return;
  }

  var root = document.documentElement;

  function allow() {
    root.classList.remove("bf-check");
  }

  function bindLinks() {
    document.addEventListener("click", function (event) {
      if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) {
        return;
      }

      var link = event.target && event.target.closest ? event.target.closest("a") : null;
      if (!link || link.target === "_blank" || link.hasAttribute("download")) return;

      var href = link.getAttribute("href") || "";
      if (href.charAt(0) === "#" || link.origin !== location.origin) return;

      try {
        sessionStorage.setItem("bf_nav", "1");
      } catch (error) {
        /* storage unavailable */
      }
    }, true);
  }

  var navigating = false;
  try {
    navigating = sessionStorage.getItem("bf_nav") === "1";
    if (navigating) sessionStorage.removeItem("bf_nav");
  } catch (error) {
    navigating = false;
  }

  if (navigating) {
    allow();
    bindLinks();
    return;
  }

  root.classList.add("bf-check");
  var next = location.pathname + location.search + location.hash;
  location.replace("/unlock.html?next=" + encodeURIComponent(next));
})();
