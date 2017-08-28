/* global gon */
var galleryIds;

$(document).ready(function() {
  galleryIds = $("#character_gallery_ids").val() || [];

  $("#character_setting_ids").select2({
    width: '100%',
    minimumResultsForSearch: 10,
    placeholder: 'Setting',
    tags: true
  });

  $("#character_gallery_ids").select2({
    width: '100%',
    minimumResultsForSearch: 10,
    placeholder: 'Default Gallery'
  });

  bindIcons();

  $("#character_template_id").change(function() {
    if ($(this).val() === "0") {
      $("#create_template").show();
    } else {
      $("#create_template").hide();
    }
  });

  $("#character_gallery_ids").change(function() {
    $("#character_default_icon_id").val('');

    var newGalleryIds = $(this).val() || [];

    // a gallery was removed
    if (galleryIds.length > newGalleryIds.length) {
      var removedGallery = $(galleryIds).not(newGalleryIds).get(0);
      galleryIds = newGalleryIds;
      $(".gallery #gallery"+removedGallery).remove();

      // if no more galleries are left, display galleryless icons
      if ($(".gallery [id^='gallery']").length === 0) {
        displayGallery('0');
      }
      return;
    }

    var newId = $(newGalleryIds).not(galleryIds).get(0);
    galleryIds = newGalleryIds;
    $(".gallery #gallery0").remove();

    if ($(".gallery #gallery" + newId).length === 0) displayGallery(newId);
  });
});

function displayGallery(newId) {
  $.get('/api/v1/galleries/'+newId, function(resp) {
    var galleryObj = $("<div>").attr({id: 'gallery'+newId}).data('id', newId);
    galleryObj.append("<br />");
    galleryObj.append($("<b>").attr({class: 'gallery-name'}).append(resp.name));
    galleryObj.append("<br />");
    var galleryIcons = $("<div>").attr({class: 'gallery-icons'});
    galleryObj.append(galleryIcons);
    for (var i = 0; i < resp.icons.length; i++) {
      var url = resp.icons[i].url;
      var keyword = resp.icons[i].keyword;
      var id = resp.icons[i].id;
      var galleryIcon = $("<img>").attr({src: url, alt: keyword, title: keyword, class: 'icon character-icon'}).data('id', id);
      galleryIcons.append(galleryIcon);
    }
    $("#selected-gallery .gallery").append(galleryObj);
    bindIcons(galleryObj);
  }, 'json');
}

function bindIcons(obj) {
  obj = obj || window.body;
  $(".character-icon", obj).click(function() {
    if ($(this).hasClass('selected-icon')) {
      $(this).removeClass('selected-icon');
      updateIcon('');
      return;
    }

    $(".selected-icon").removeClass('selected-icon');
    $(this).addClass('selected-icon');
    updateIcon($(this).data('id'));
  });
}

function updateIcon(id) {
  if (gon.character_id) {
    $.ajax({
      url: '/api/v1/characters/'+gon.character_id,
      type: 'PUT',
      data: {character: {default_icon_id: id}}
    });
  } else {
    $("#character_default_icon_id").val(id);
  }
}
