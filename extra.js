// pkgdown extracts the README's <h1> and inserts its own
// <img src="logo.png" class="logo"> in the home-page header, ignoring
// the .gif we put in the README. Swap that <img> to the animated gif.
//
// pkgdown copies man/figures/* to docs/reference/figures/, so logo.gif
// always lives at <docs-root>/reference/figures/logo.gif. We compute the
// path to docs root from this script's own src (which pkgdown emits as
// "extra.js" on root pages, "../extra.js" one level deep, etc.).
window.addEventListener("DOMContentLoaded", function () {
  var thisScript = document.querySelector('script[src$="extra.js"]');
  var base = thisScript
    ? thisScript.getAttribute("src").replace(/extra\.js$/, "")
    : "";
  var gif = base + "reference/figures/logo.gif";

  document.querySelectorAll("img.logo, img[src$='logo.png']").forEach(function (img) {
    img.src = gif;
  });
});
