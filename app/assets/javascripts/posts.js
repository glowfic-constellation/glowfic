$(document).ready(function() {
  $("#post_board_id").chosen({
    width: '200px',
    disable_search_threshold: 20,
  });

  $("#post_privacy").chosen({
    width: '200px',
    disable_search_threshold: 20,
  });

  $("#post_post_viewer_ids").chosen({
    width: '200px',
    disable_search_threshold: 20,
    placeholder_text_multiple: 'Choose user(s) to view this post'
  });

  $("#active_character").chosen({
    disable_search_threshold: 10,
    width: '100%',
  });

  $("#post_privacy").change(function() {
    if($(this).val() == 2) { // TODO don't hardcode, should be PRIVACY_ACCESS
      $("#access_list").show();
    } else {
      $("#access_list").hide();
    }
  });

  $("#submit_button").click(function() {
    $("#preview_button").removeAttr('data-disable-with').attr('disabled', 'disabled');
    return true;
  });

  $("#preview_button").click(function() {
    $("#submit_button").removeAttr('data-disable-with').attr('disabled', 'disabled');
    action = $("#post_form").attr('action');
    if(action != "/posts" && action != "/replies") { 
      if(action.startsWith("/posts")) {
        var post_id = action.substring(7);
        $("<input>").attr("type", "hidden").attr("name", "post_id").val(post_id).appendTo('#post_form');
      } else {
        var reply_id = action.substring(9);
        $("<input>").attr("type", "hidden").attr("name", "reply_id").val(reply_id).appendTo('#post_form');
      }
    }
    $("#post_form").attr('action', '/posts/preview');
    $("input[name=_method]").val('post');
    return true;
  });

  if ($("#current-icon").length) {
    if (gon.current_user.active_character_id != null && $(".gallery-icon").length > 1) {
     bindIcon(); 
    }
  }
  bindGallery();

  $("#swap-icon").click(function () {
    $('#character-selector').toggle();
  });

  $("#active_character").change(function() { 
    // Set the ID
    var id = $(this).val();
    $("#reply_character_id").val(id);

    // Set name in name label
    var name = $('#active_character :selected').text();
    if (id == '') {
      name = gon.current_user.username;
    }
    $("#char-name").text(name);

    // Handle page interactions
    $("#character-selector").hide();
    $("#current-icon-holder").unbind();
    $("#current-icon").css({
      'background-image':'url("/images/loading.gif")',
      'background-position':'40px',
      'background-size':'25%',
      'background-repeat':'no-repeat',
    });

    $.post(gon.character_path, {'character_id':id}, function (resp) {
      if (id == '') {
        url = gon.current_user.avatar.url;
        if (url != null) {
          if (!$("#current-icon").length) { $("#current-icon-holder").append("<img id='current-icon' class='icon' />"); }
          $("#current-icon").show().attr('src', url).removeClass('pointer'); 
          $("#reply_icon_id").val(gon.current_user.avatar.id);
        } else {
          $("#current-icon").remove()
        }
      } else if (resp['default'] == undefined) {
        $("#current-icon").hide();
        $("#reply_icon_id").val('');
      } else {
        if (!$("#current-icon").length) { $("#current-icon-holder").append("<img id='current-icon' class='icon' />"); }
        $("#current-icon").show().attr('src', resp['default']['url']);
        $("#reply_icon_id").val(resp['default']['id']);
        $("#gallery").html('<table id="gallery-table"><tbody></tbody></table>');
        var len = resp['gallery'].length;
        if(len > 1) {
          bindIcon();
          $("#current-icon").addClass('pointer');
        }
        for (var i = 0; i < len; i++) {
          if(i % 6 == 0) { $("#gallery-table tbody").append('<tr>'); }
          var img_id = resp['gallery'][i]['id'];
          var img_url = resp['gallery'][i]['url'];
          var img_key = resp['gallery'][i]['keyword'];
          $("#gallery-table tbody").append("<td class='vtop centered'><div class='gallery-icon'><img src='" + img_url + "' id='" + img_id + "' class='icon' /><br />"+img_key+"</div></td>");
          if(i % 6 == 5) { $("#gallery-table tbody").append('</tr>'); }
        }
        bindGallery();
      }
    });
  });

  $(document).bind("keydown", function(e){ 
    e = e || window.event;
    var charCode = e.which || e.keyCode;
    if(charCode == 27) {
      $('#icon-overlay').hide();
      $('#gallery').hide();
      $('#character-selector').hide();
    }
  });

  $(document).click(function(e) {
    var target = e.target;

    if (!$(target).is('#current-icon-holder') && 
      !$(target).parents().is('#current-icon-holder') &&
      !$(target).is('#gallery') && 
      !$(target).parents().is('#gallery')) {
        $('#icon-overlay').hide();
        $('#gallery').hide();
    }

    if (!$(target).is('#character-selector') && 
      !$(target).is('#swap-icon') && 
      !$(target).parents().is('#character-selector')) {
        $('#character-selector').hide();
    }
  });
});

bindGallery = function() {
  $("#gallery img").click(function() {
    $('#icon-overlay').hide();
    $('#gallery').hide();
    $("#reply_icon_id").val($(this).attr('id'));
    $("#current-icon").attr('src', $(this).attr('src'));
    $("#current-icon").attr('title', $(this).attr('title'));
    $("#current-icon").attr('alt', $(this).attr('alt'));
  });
};

bindIcon = function() {
  $('#current-icon-holder').click(function() {
    $('#icon-overlay').toggle();
    $('#gallery').toggle();
  });
}
