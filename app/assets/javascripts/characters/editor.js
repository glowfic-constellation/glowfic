var gallery_ids = [];

$(document).ready(function() {
  gallery_ids = jQuery.map($(".gallery div"), function(el) { return el.dataset['id']; });

  $("#character_template_id").chosen({
    width: '100%',
    disable_search_threshold: 10,
  });

  $("#character_gallery_ids").chosen({
    width: '100%',
    disable_search_threshold: 10,
    placeholder_text_multiple: 'Default Gallery'
  });

  $("#character_character_group_id").chosen({
    width: '100%',
    disable_search_threshold: 10,
  });

  bindIcons();

  $("#character_template_id").change(function () {
    if ($(this).val() != "0") {
      $("#create_template").hide();
    } else {
      $("#create_template").show();
    }
  });

  $("#character_character_group_id").change(function () {
    if ($(this).val() != "0") {
      $("#create_group").hide();
    } else {
      $("#create_group").show();
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
      if (gallery_ids == '') {
        $.get('/galleries/0', function (resp) {
          $("#selected-gallery .gallery").html("<div id='gallery0' data-id='0'></div>");
          for(var i = 0; i < resp['icons'].length; i++) {
            var url = resp['icons'][i]['url'];
            var keyword = resp['icons'][i]['keyword'];
            var id = resp['icons'][i]['id'];
            $("#selected-gallery .gallery #gallery0").append('<img src="'+url+'" alt="'+keyword+'" title="'+keyword+'" class="icon character-icon" id="'+id+'" />');  
          }
          bindIcons();
        });
      }
      return;
    }

    var new_id = $(new_gallery_ids).not(gallery_ids).get();
    gallery_ids = new_gallery_ids;
    $(".gallery #gallery0").remove();

    $.get('/galleries/'+new_id, function (resp) {
      $("#selected-gallery .gallery").append("<div id='gallery"+new_id+"' data-id='"+new_id+"'><br><b>"+resp['name']+"</b><br></div>");
      for(var i = 0; i < resp['icons'].length; i++) {
        var url = resp['icons'][i]['url'];
        var keyword = resp['icons'][i]['keyword'];
        var id = resp['icons'][i]['id'];
        $("#selected-gallery .gallery #gallery"+new_id).append('<img src="'+url+'" alt="'+keyword+'" title="'+keyword+'" class="icon character-icon" id="'+id+'" />');  
      }
      bindIcons();
    });
  });
});

function bindIcons() {
  $(".character-icon").click(function() {
    if($(this).hasClass('selected-icon')) { return; }
    $(".selected-icon").removeClass('selected-icon');
    $(this).addClass('selected-icon');
    var id = $(this).attr('id');

    if (gon.character_id) {
      $.post('/characters/'+gon.character_id+'/icon', {'icon_id':id}, function(resp) {});
    } else {
      $("#character_default_icon_id").val(id);
    }
  });
};