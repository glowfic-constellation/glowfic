var image_ids = [];
var skip_warning = false;
$(document).ready(function() {
  bindGalleryIcons(".add-gallery-icon");

  $("#add-gallery-icons").submit(function() {
    if (image_ids.length < 1) return false;
    $("#image_ids").val(image_ids);
    skip_warning = true;
    return true;
  });

  $(".gallery-minmax").click(function() {
    var gallery_id = $(this).data('id');

    // Hide icons if they're already visible
    if ($("#icons-" + gallery_id).is(':visible')) {
      $("#icons-" + gallery_id).hide();
      $("#minmax-" + gallery_id).text("+");
      return true;
    }

    // Show icons if they're hidden
    $("#icons-" + gallery_id).show();
    $("#minmax-" + gallery_id).text("-");
    if ($("#icons-" + gallery_id).html().length > 0) { return true; }

    // Load and bind icons if they have not already been loaded
    $.get("/api/v1/galleries/" + gallery_id, {}, function(resp) {
      $.each(resp.icons, function(index, icon) {
        var icon_div = $("<div>").attr({class: 'gallery-icon'});
        var icon_img = $("<img>").attr({src: icon.url, alt: icon.keyword, title: icon.keyword, 'class': 'icon add-gallery-icon', 'data-id': icon.id});
        icon_div.append(icon_img).append("<br>").append($("<span>").attr({class: 'icon-keyword'}).append(icon.keyword));
        $("#icons-" + gallery_id).append(icon_div);
      });
      bindGalleryIcons("#icons-" + gallery_id + " .add-gallery-icon");
    });
  });
});

$(window).on('beforeunload', function() {
  if (skip_warning || image_ids.length === 0) return;
  return "Are you sure you wish to navigate away? You have " + image_ids.length + " image(s) selected.";
});

function bindGalleryIcons(css_selector) {
  $(css_selector).click(function() {
    $(this).toggleClass('selected-icon');
    if ($(this).hasClass('selected-icon')) {
      image_ids.push(this.dataset.id);
    } else {
      image_ids.pop(this.dataset.id);
    }
  });
}
