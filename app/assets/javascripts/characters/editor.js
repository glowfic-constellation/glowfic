/* global gon, createTagSelect */
var galleryIds;
var galleryGroupIds = [];
var galleryGroups = {};

$(document).ready(function() {
  gon.gallery_groups.forEach(function(galleryGroup) {
    galleryGroups[galleryGroup.id] = galleryGroup;
  });
  galleryIds = $("#character_ungrouped_gallery_ids").val() || [];
  galleryGroupIds = $("#character_gallery_group_ids").val() || [];

  $("#character_setting_ids").select2({
    width: '100%',
    minimumResultsForSearch: 10,
    placeholder: 'Setting',
    tags: true
  });

  $("#character_ungrouped_gallery_ids").select2({
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

  $("#character_ungrouped_gallery_ids").change(function() {
    $("#character_default_icon_id").val('');

    var newGalleryIds = $(this).val() || [];

    // a gallery was removed
    if (galleryIds.length > newGalleryIds.length) {
      var removedGallery = $(galleryIds).not(newGalleryIds).get(0);
      galleryIds = newGalleryIds;
      if (findGalleryInGroups(removedGallery)) return;
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

    // display only if not visible (for gallery groups)
    if ($(".gallery #gallery" + newId).length === 0) displayGallery(newId);
  });

  $("#character_gallery_group_ids").change(function() {
    $("#character_default_icon_id").val('');

    var newGalleryGroupIds = $(this).val() || [];

    // a gallery group was removed
    if (galleryGroupIds.length > newGalleryGroupIds.length) {
      var removedGroup = $(galleryGroupIds).not(newGalleryGroupIds).get(0);
      galleryGroupIds = newGalleryGroupIds;
      if (removedGroup.substring(0, 1) === '_') return; // skip uncreated tags

      var group = galleryGroups[parseInt(removedGroup)];
      delete galleryGroups[parseInt(removedGroup)];

      // delete unfound galleries from icons list
      group.gallery_ids.forEach(function(galleryId) {
        if (findGalleryInGroups(galleryId) || galleryIds.indexOf(galleryId.toString()) >= 0) return;
        $(".gallery #gallery" + galleryId).remove();
        galleryIds = $.makeArray($(galleryIds).not([galleryId.toString()]));
      });

      // if no more galleries remain, display galleryless icons
      if ($(".gallery [id^='gallery']").length === 0) {
        displayGallery('0');
      }
      return;
    }

    var newId = $(newGalleryGroupIds).not(galleryGroupIds).get(0);
    galleryGroupIds = newGalleryGroupIds;
    if (typeof newId === 'undefined') return;
    if (newId.substring(0, 1) === '_') return; // skip uncreated tags

    // fetch galleryGroup galleryIds
    $.get('/api/v1/tags/'+newId, {user_id: gon.user_id}, function(resp) {
      var ids = resp.gallery_ids;
      galleryGroups[resp.id] = {gallery_ids: ids};

      if (ids.length === 0) return; // return if empty

      $(".gallery #gallery0").remove();
      ids.forEach(function(id) {
        if ($(".gallery #gallery" + id).length === 0) {
          displayGallery(id);
        }
      });
    });
  });

  createTagSelect("GalleryGroup", "gallery_group", "character", {user_id: gon.user_id});
});

function findGalleryInGroups(galleryId) {
  galleryId = parseInt(galleryId);
  var found = false;
  Object.keys(galleryGroups).forEach(function(groupId) {
    if (galleryGroups[groupId].gallery_ids.indexOf(galleryId) >= 0) found = true;
  });
  return found;
}

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
