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
    if (wasVisible) { return true; }
    if ($("#icons-" + galleryId + " .gallery").html().length > 0) { return true; }

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
});
