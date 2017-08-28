/* global gon */
$(document).ready(function() {
  $(".gallery-box").click(function() {
    // Update toggle +/-
    var toggleBox = $(this).children('.view-button').first().children('img').first();
    var wasVisible = (toggleBox.attr('src').includes("up"));
    toggleBox.attr('src', (wasVisible ? '/images/bullet_arrow_down.png' : '/images/bullet_arrow_up.png'));

    // Toggle display
    var galleryId = $(this).data('id');
    $("#icons-" + galleryId).toggle();

    // Nothing more necessary if collapsing or already loaded
    if (wasVisible) { return; }
    if ($("#icons-" + galleryId + " .gallery").html().length > 0) { return; }

    // Load and bind icons if they have not already been loaded
    $.get("/api/v1/galleries/" + galleryId, {user_id: gon.user_id}, function(resp) {
      $.each(resp.icons, function(index, icon) {
        var iconDiv = $("<div>").attr({class: 'gallery-icon'});
        var iconLink = $("<a>").attr({href: "/icons/" + icon.id});
        var iconImg = $("<img>").attr({src: icon.url, alt: icon.keyword, title: icon.keyword, 'class': 'icon'});
        iconLink.append(iconImg).append("<br>").append($("<span>").attr({class: 'icon-keyword'}).append(icon.keyword));
        iconDiv.append(iconLink);

        // Add control buttons for the owner
        if ($("#icons-" + galleryId + " .icons-remove").length > 0) {
          var iconCheckbox = $("<input>").attr({id: 'marked_ids_'+icon.id, name: 'marked_ids[]', type: 'checkbox'}).val(icon.id);
          iconDiv.append($("<div>").attr({class: 'select-button'}).append(iconCheckbox));
        }

        $("#icons-" + galleryId + " .gallery").append(iconDiv);
      });
    });
  });

  $(".tag-item").hover(function mouseIn() {
    $(this).removeClass('semiplusopaque');
  }, function mouseOut() {
    $(this).addClass('semiplusopaque');
  });

  // add ellipsis box for many (> 5) tags
  $(".tag-box").each(function() {
    var tagBox = $(this);
    var tagBoxItems = $(".tag-item", tagBox);
    if (tagBoxItems.length <= 5) return;
    var hiddenTags = tagBoxItems.slice(4);
    hiddenTags.hide();
    var ellipsisBox = $("<span>").attr({class: 'tag-item semiopaque pointer', title: 'Click to show more tags…'}).append("...");
    var recollapseBox = $("<span>").attr({class: 'tag-item semiopaque pointer', title: 'Click to hide extra tags…'}).append("←").hide();
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
