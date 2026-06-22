/* Dynamic icon sizing for the alternating-icons reply layout.
 *
 * Inspired by jbeshir/glowficlog's compact reader: instead of a fixed icon on
 * every reply, scale each reply's icon to roughly match the height of its own
 * post body (clamped between MIN and CAP). Short, rapid-fire replies get a
 * small icon so the exchange stays dense; long replies keep a full-size icon.
 *
 * We size to the post's own content height rather than the distance to the next
 * same-side reply (jbeshir's gutter approach): the icon here lives in a floated
 * info chip, so an icon taller than its body would inflate the post and feed
 * back into the layout. Capping at the body height keeps it stable.
 */
$(document).ready(function() {
  if (!document.body.classList.contains('alternating-icons')) return;

  const MIN = 28; // never shrink an icon below this (stays recognizable)
  const CAP = 96; // never grow past this (matches the non-alternating icon size)

  const clamp = function(min, value, max) {
    return Math.min(max, Math.max(min, value));
  };

  const sizeIcons = function() {
    const posts = document.querySelectorAll('#content .post-container');
    Array.from(posts).forEach(function(post) {
      const icon = post.querySelector('.post-icon img, .post-icon div');
      const content = post.querySelector('.post-content');
      if (!icon || !content) return;

      const size = clamp(MIN, content.offsetHeight, CAP);
      icon.style.width = size + 'px';
      icon.style.height = size + 'px';
    });
  };

  const debounce = function(fn, wait) {
    let timer = null;
    return function() {
      if (timer) clearTimeout(timer);
      timer = setTimeout(fn, wait);
    };
  };

  sizeIcons();
  // Webfonts/images can land after ready and change body heights; recompute.
  $(window).on('load', sizeIcons);
  $(window).on('resize', debounce(sizeIcons, 150));
});
