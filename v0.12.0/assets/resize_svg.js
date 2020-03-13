"use strict";

function getParentContentWidth(element) {
  var parent = element.parentNode;
  var s = window.getComputedStyle(parent);
  var padding = parseFloat(s.paddingLeft) + parseFloat(s.paddingRight);
  return parent.clientWidth - padding;
}

function resizeSvgs() {
  var svgs = document.getElementsByTagName("svg");
  for (var i = 0; i < svgs.length; ++i) {
    var svg = svgs[i];
    var contentWidth = getParentContentWidth(svg);
    var w = svg.width.baseVal.value;
    var h = svg.height.baseVal.value;
    var cw = Math.min(contentWidth, w * 1.5625); // 150dpi
    svg.style.width = cw + "px";
    svg.style.height = (cw * h / w) + "px";
  }
}

window.addEventListener("load", resizeSvgs, false);
window.addEventListener("resize", resizeSvgs, false);
