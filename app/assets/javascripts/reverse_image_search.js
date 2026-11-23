/* exported updateReverseImageSearch */

$(document).ready(function() {
  // Refill any server-rendered links so encoding stays consistent with in-page uploads.
  $(".reverse-image-search[data-image-url]").each(function() {
    updateReverseImageSearch(this, $(this).attr('data-image-url'));
  });
});

// Point each reverse-image-search link at imageUrl and reveal the container. Passing an
// empty imageUrl resets the links and hides the container (e.g. a cleared upload row).
function updateReverseImageSearch(container, imageUrl) {
  const box = $(container);
  if (box.length === 0) return;

  if (!imageUrl) {
    box.removeAttr('data-image-url').addClass('hidden');
    box.find('a[data-search-template]').attr('href', '#');
    return;
  }

  box.attr('data-image-url', imageUrl);
  box.find('a[data-search-template]').each(function() {
    const template = $(this).attr('data-search-template');
    $(this).attr('href', template.replace('{url}', encodeURIComponent(imageUrl)));
  });
  box.removeClass('hidden');
}
