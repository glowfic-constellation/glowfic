/* Dynamic icon sizing for the alternating-icons reply layout.
 *
 * Inspired by jbeshir/glowficlog's compact reader: instead of a fixed icon on
 * every reply, scale each reply's icon to roughly match the height of its own
 * post body (clamped between MIN and CAP). Short, rapid-fire replies get a
 * small icon so the exchange stays dense; long replies keep a full-size icon.
 *
 * We size to the post's *own* content height rather than the distance to the
 * next same-side reply (jbeshir's gutter approach): the icon here lives in a
 * floated info chip, so an icon taller than its body would inflate the post and
 * feed back into the layout. Capping at the body height keeps it stable.
 */
(function() {
  'use strict';

  var MIN = 28;  // never shrink an icon below this (stays recognizable)
  var CAP = 96;  // never grow past this (matches the non-alternating icon size)

  function clamp(min, value, max) {
    return Math.min(max, Math.max(min, value));
  }

  function sizeIcons() {
    if (!document.body.classList.contains('alternating-icons')) return;

    var posts = document.querySelectorAll('#content .post-container');
    for (var i = 0; i < posts.length; i++) {
      var post = posts[i];
      var icon = post.querySelector('.post-icon img, .post-icon div');
      var content = post.querySelector('.post-content');
      if (!icon || !content) continue;

      var size = clamp(MIN, content.offsetHeight, CAP);
      icon.style.width = size + 'px';
      icon.style.height = size + 'px';
    }
  }

  function debounce(fn, wait) {
    var timer = null;
    return function() {
      if (timer) clearTimeout(timer);
      timer = setTimeout(fn, wait);
    };
  }

  $(document).ready(sizeIcons);
  // Webfonts/images can land after ready and change body heights; recompute.
  $(window).on('load', sizeIcons);
  $(window).on('resize', debounce(sizeIcons, 150));
})();
