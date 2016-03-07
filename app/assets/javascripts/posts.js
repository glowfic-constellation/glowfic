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

  $(".post-screenname").each(function (index) {
    if($(this).height() > 20) {
      $(this).css('font-size', "14px");
      if($(this).height() > 20 ) { $(this).css('font-size', "12px"); };
    }
  });

  $("#post_privacy").change(function() {
    if($(this).val() == 2) { // TODO don't hardcode, should be PRIVACY_ACCESS
      $("#access_list").show();
    } else {
      $("#access_list").hide();
    }
  });

  $(".post-expander").click(function() {
    $(".post-expander .info").remove();
    $(".post-expander .hidden").show();
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

  if($(".gallery-icon").length > 1) {
    bindIcon();
    bindGallery();
  }

  $("#swap-icon").click(function () {
    $('#character-selector').toggle();
    $('html, body').scrollTop($("#post-editor").offset().top);
  });

  $("#active_character_chosen").click(function () {
    $('html, body').scrollTop($("#post-editor").offset().top);
  });

  $("#active_character").change(function() { 
    // Set the ID
    var id = $(this).val();
    $("#reply_character_id").val(id);

    // Handle page interactions
    $("#character-selector").hide();
    $("#current-icon-holder").unbind();

    // Handle special case where just setting to your base account
    if (id == '') {
      $("#post-editor .post-character").hide();
      $("#post-editor .post-screenname").hide();
      $("#post-editor #post-author-spacer").show();
      var url = gon.current_user.avatar.url;
      if(url != null) {
        var aid = gon.current_user.avatar.id;
        $("#current-icon").attr('src', url).addClass('pointer');
        $("#reply_icon_id").val(aid);
        $("#gallery").html("");
        $("#gallery").append("<div class='gallery-icon'><img src='" + url + "' id='" + aid + "' class='icon' /><br />Avatar</div>");
        $("#gallery").append("<div class='gallery-icon'><img src='/images/no-icon.png' id='' class='icon' /><br />No Icon</div>");
        bindIcon();
        bindGallery();
      }
    }

    $.post(gon.character_path, {'character_id':id}, function (resp) {
      if(id == '') { return; }
      $("#post-editor #post-author-spacer").hide();
      $("#post-editor .post-character").show().html(resp['name']);
      if(resp['screenname'] == undefined) {
        $("#post-editor .post-screenname").hide();
      } else {
        $("#post-editor .post-screenname").show().html(resp['screenname']);
      }
      if (resp['default'] == undefined) {
        $("#current-icon").attr('src', '/images/no-icon.png').removeClass('pointer');
        $("#reply_icon_id").val('');
      } else {
        $("#current-icon").attr('src', resp['default']['url']).addClass('pointer');
        $("#reply_icon_id").val(resp['default']['id']);
        $("#gallery").html("");
        var len = resp['gallery'].length;
        for (var i = 0; i < len; i++) {
          var img_id = resp['gallery'][i]['id'];
          var img_url = resp['gallery'][i]['url'];
          var img_key = resp['gallery'][i]['keyword'];
          $("#gallery").append("<div class='gallery-icon'><img src='" + img_url + "' id='" + img_id + "' class='icon' /><br />"+img_key+"</div>");
        }
        $("#gallery").append("<div class='gallery-icon'><img src='/images/no-icon.png' id='' class='icon' /><br />No Icon</div>");
        bindGallery();
        bindIcon();
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
    id = $(this).attr('id');
    $("#reply_icon_id").val(id);
    $('#icon-overlay').hide();
    $('#gallery').hide();
    $("#current-icon").attr('src', $(this).attr('src'));
    $("#current-icon").attr('title', $(this).attr('title'));
    $("#current-icon").attr('alt', $(this).attr('alt'));
  });
};

bindIcon = function() {
  $('#current-icon-holder').click(function() {
    $('#icon-overlay').toggle();
    $('#gallery').toggle();
    $('html, body').scrollTop($("#post-editor").offset().top);
  });
}
