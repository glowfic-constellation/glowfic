/* global gon */
$(document).ready(function() {
  const anchor = window.location.hash;
  if (anchor.length > 0 && /^#gallery-[0-9]{1,}$/.test(anchor)) {
    displayGallery($(anchor + " .gallery-box"));
  }

  $(".gallery-box").click(function() {
    displayGallery($(this));
  });

  $(".tag-item").hover(function mouseIn() {
    $(this).removeClass('semiplusopaque');
  }, function mouseOut() {
    $(this).addClass('semiplusopaque');
  });

  // add ellipsis box for many (> 5) tags
  $(".tag-box").each(function() {
    const tagBox = $(this);
    const tagBoxItems = $(".tag-item", tagBox);
    if (tagBoxItems.length <= 5) return;

    const hiddenTags = tagBoxItems.slice(4);
    hiddenTags.hide();

    const ellipsisBox = $("<span>").attr({class: 'tag-item semiopaque pointer', title: 'Click to show more tags…'}).append("...");
    const recollapseBox = $("<span>").attr({class: 'tag-item semiopaque pointer', title: 'Click to hide extra tags…'}).append("←").hide();

    ellipsisBox.add(recollapseBox).hover(function mouseIn() {
      $(this).removeClass('semiplusopaque');
    }, function mouseOut() {
      $(this).addClass('semiplusopaque');
    });

    tagBox.append(ellipsisBox).append(' ').append(recollapseBox); // inline-block cares about spaces for formatting

    ellipsisBox.click(function() {
      hiddenTags.show();
      ellipsisBox.hide();
      recollapseBox.show();
    });
    recollapseBox.click(function() {
      hiddenTags.hide();
      recollapseBox.hide();
      ellipsisBox.show();
    });
  });
});

function displayGallery(elem) {
  // Update toggle +/-
  const toggleBox = elem.children('.view-button').first();
  const wasVisible = toggleBox.children('img.up-arrow').is(':visible');
  toggleBox.children('img.down-arrow').first().toggle();
  toggleBox.children('img.up-arrow').first().toggle();

  // Toggle display
  const galleryId = elem.data('id');
  $("#icons-" + galleryId).toggle();

  // Nothing more necessary if collapsing or already loaded
  if (wasVisible) return;
  if (elem.data('loading') || elem.data('loaded')) return;

  // Load and bind icons if they have not already been loaded
  elem.data('loading', true);
  $.authenticatedAjax({
    url: "/api/v1/galleries/" + galleryId,
    data: {user_id: gon.user_id}
  }).done(function(resp) {
    $.each(resp.icons, function(_, icon) {
      const iconDiv = $("<div>").attr({class: 'gallery-icon'});
      const iconLink = $("<a>").attr({href: "/icons/" + icon.id});
      const iconImg = $("<img>").attr({src: icon.url, alt: icon.keyword, title: icon.keyword, 'class': 'icon'});
      iconLink.append(iconImg).append("<br>").append($("<span>").attr({class: 'icon-keyword'}).text(icon.keyword));
      iconDiv.append(iconLink);

      // Add control buttons for the owner
      if ($("#icons-" + galleryId + " .icons-remove").length > 0) {
        const iconCheckbox = $("<input>").attr({name: 'marked_ids[]', type: 'checkbox'}).val(icon.id);
        iconDiv.append($("<div>").attr({class: 'select-button'}).append(iconCheckbox));
      }

      $("#icons-" + galleryId + " .gallery").append(iconDiv);
    });
    elem.data('loading', false).data('loaded', true);
  }).fail(function(_, textStatus, errorThrown) {
    elem.data('loading', false).trigger('click');
    alert("Error loading gallery " + galleryId + "! Please reload the page and try again.\nTechnical details: " + textStatus + " " + errorThrown);
  });
}
