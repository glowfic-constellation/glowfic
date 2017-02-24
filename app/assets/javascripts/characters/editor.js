var gallery_ids = [];

$(document).ready(function() {
  gallery_ids = jQuery.map($(".gallery div"), function(el) { return el.dataset['id']; });

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

  $("#character_template_id").change(function () {
    if ($(this).val() !== "0") {
      $("#create_template").hide();
    } else {
      $("#create_template").show();
    }
  });

  $("#character_gallery_ids").change(function() {
    $("#character_default_icon_id").val('');

    var new_gallery_ids = $(this).val() || [];
    var new_gallery;

    // a gallery was removed
    if(gallery_ids.length > new_gallery_ids.length) {
      var removed_gallery = $(gallery_ids).not(new_gallery_ids).get();
      gallery_ids = new_gallery_ids;
      $(".gallery #gallery"+removed_gallery).remove();

      // if no more galleries are left, display galleryless icons
      if (gallery_ids === '') {
        displayGallery('0');
      }
      return;
    }

    var new_id = $(new_gallery_ids).not(gallery_ids).get();
    gallery_ids = new_gallery_ids;
    $(".gallery #gallery0").remove();

    displayGallery(new_id);
  });
});

function displayGallery(new_id){
  $.get('/galleries/'+new_id, function (resp) {
    html_string = "<div id='gallery"+new_id+"' data-id='"+new_id+"'><br /><b class='gallery-name'>"+resp.name+"</b><br /><div class='gallery-icons'>";
    for(var i = 0; i < resp.icons.length; i++) {
      var url = resp.icons[i].url;
      var keyword = resp.icons[i].keyword;
      var id = resp.icons[i].id;
      html_string += '<img src="'+url+'" alt="'+keyword+'" title="'+keyword+'" class="icon character-icon" id="'+id+'" />';
    }
    html_string += "</div>";
    $("#selected-gallery .gallery").append(html_string);
    bindIcons();
  }, 'json');
}

function bindIcons() {
  $(".character-icon").click(function() {
    if($(this).hasClass('selected-icon')) {
      $(this).removeClass('selected-icon');
      updateIcon('');
      return;
    }

    $(".selected-icon").removeClass('selected-icon');
    $(this).addClass('selected-icon');
    updateIcon($(this).attr('id'));
  });
}

function updateIcon(id) {
    if (gon.character_id) {
      $.ajax({
        url: '/api/v1/characters/'+gon.character_id,
        type: 'PUT',
        data: {'character': {'default_icon_id':id}},
        success: function(resp) {}
      });
    } else {
      $("#character_default_icon_id").val(id);
    }
}
