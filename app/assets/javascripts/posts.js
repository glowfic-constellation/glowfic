$(document).ready(function() {
  // TODO fix hack
  // Hack because having In Thread characters as a group in addition to Template groups
  // duplicates characters in the dropdown, and therefore multiple options are selected
  var selectd;
  $("#active_character option[selected]").each(function(){
    if (!selectd) selectd = this;
    $(this).prop("selected", false);
  });
  $(selectd).prop("selected", true);

  PRIVACY_ACCESS = 2; // TODO don't hardcode

  // Adding Select2 UI to relevant selects
  $("#post_board_id").select2({
    width: '200px',
    minimumResultsForSearch: 20,
  });

  $("#post_section_id").select2({
    width: '200px',
    minimumResultsForSearch: 20,
  });

  $("#post_privacy").select2({
    width: '200px',
    minimumResultsForSearch: 20,
  });

  $("#post_viewer_ids").select2({
    width: '200px',
    minimumResultsForSearch: 20,
    placeholder: 'Choose user(s) to view this post'
  });

  $("#post_tag_ids").select2({
    tags: true,
    tokenSeparators: [','],
    placeholder: 'Enter tag(s) separated by commas',
    ajax: {
      delay: 200,
      url: '/tags',
      dataType: 'json',
      data: function(term, page) {
        return { q: term['term'] };
      },
    },
    width: '300px'
  });

  $("#post_setting_ids").select2({
    tags: true,
    tokenSeparators: [','],
    placeholder: 'Enter setting(s) separated by commas',
    ajax: {
      delay: 200,
      url: '/tags',
      dataType: 'json',
      data: function(term, page) {
        return {
          q: term['term'],
          t: 'setting',
        };
      },
    },
    width: '300px'
  });

  $("#post_warning_ids").select2({
    tags: true,
    tokenSeparators: [','],
    placeholder: 'Enter warning(s) separated by commas',
    ajax: {
      delay: 200,
      url: '/tags',
      dataType: 'json',
      data: function(term, page) {
        return {
          q: term['term'],
          t: 'warning',
        };
      },
    },
    width: '300px'
  });

  $("#active_character").select2({
    minimumResultsForSearch: 10,
    width: '100%',
  });

  // TODO fix hack
  // Resizes screennames to be slightly smaller if they're long for UI reasons
  $(".post-screenname").each(function (index) {
    if($(this).height() > 20) {
      $(this).css('font-size', "14px");
      if($(this).height() > 20 ) { $(this).css('font-size', "12px"); };
    }
  });

  // Hack to deal with Firefox's "helpful" caching of form values on soft refresh (now via IDs)
  var selectedCharID = $("#reply_character_id").val();
  var displayCharID = $("#post-editor .post-character").data('character-id');
  var selectedIconID = $("#reply_icon_id").val();
  var displayIconID = $("#current-icon").data('icon-id');
  if (selectedCharID != displayCharID) {
    getAndSetCharacterData(selectedCharID, {restore_icon: true});
    $("#active_character").val(selectedCharID).trigger("chosen:updated");
  } else {
    if ($(".gallery-icon").length > 1) { /* Bind icon & gallery only if not resetting character, else it duplicate binds */
      bindIcon();
      bindGallery();
    }
    if (selectedIconID != displayIconID) {
      setIconFromId(selectedIconID); // Handle the case where just the icon was cached
    }
  }

  if ($("#post_privacy").val() != PRIVACY_ACCESS)
    $("#access_list").hide();

  // Bind both change() and keyup() in the icon keyword dropdown because Firefox doesn't
  // respect up/down key selections in a dropdown as a valid change() trigger
  $("#icon_dropdown").change(function() { setIconFromId($(this).val()); });
  $("#icon_dropdown").keyup(function() { setIconFromId($(this).val()); });

  if ($("#post_section_id").val() == '') { setSections(); }
  $("#post_board_id").change(function() { setSections(); });

  $('.view-button').click(function() {
    if(this.id == 'rtf') {
      $("#html").removeClass('selected');
      $("#editor_mode").val('rtf')
      $(this).addClass('selected');
      tinyMCE.execCommand('mceAddEditor', true, 'post_content');
      tinyMCE.execCommand('mceAddEditor', true, 'reply_content');
    } else if (this.id == 'html') {
      $("#rtf").removeClass('selected');
      $("#editor_mode").val('html')
      $(this).addClass('selected');
      tinyMCE.execCommand('mceRemoveEditor', false, 'post_content');
      tinyMCE.execCommand('mceRemoveEditor', false, 'reply_content');
    };
  });

  $("#post_privacy").change(function() {
    if($(this).val() == PRIVACY_ACCESS) {
      $("#access_list").show();
    } else {
      $("#access_list").hide();
    }
  });

  $("#submit_button").click(function() {
    $("#draft_button").removeAttr('data-disable-with').attr('disabled', 'disabled');
    return true;
  });

  $("#draft_button").click(function() {
    $("#submit_button").removeAttr('data-disable-with').attr('disabled', 'disabled');
    return true;
  });

  $("#swap-icon").click(function () {
    $('#character-selector').toggle();
    $('html, body').scrollTop($("#post-editor").offset().top);
  });

  $("#active_character").on('select2:close', function () {
    $('html, body').scrollTop($("#post-editor").offset().top);
  });

  $("#active_character").change(function() {
    // Set the ID
    var id = $(this).val();
    $("#reply_character_id").val(id);
    getAndSetCharacterData(id);
  });

  // Hides selectors when you hit the escape key
  $(document).bind("keydown", function(e){
    e = e || window.event;
    var charCode = e.which || e.keyCode;
    if(charCode == 27) {
      $('#icon-overlay').hide();
      $('#gallery').hide();
      $('#character-selector').hide();
    }
  });

  // Hides selectors when you click outside them
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
    setIconFromId(id, $(this));
  });
};

bindIcon = function() {
  $('#current-icon-holder').click(function() {
    $('#icon-overlay').toggle();
    $('#gallery').toggle();
    $('html, body').scrollTop($("#post-editor").offset().top);
  });
};

galleryString = function(gallery, multiGallery) {
  var iconsString = "";
  var icons = gallery["icons"];

  for (var i=0; i<icons.length; i++) {
    iconsString += iconString(icons[i]);
  }

  if(!multiGallery) { return iconsString; }

  var nameString = "<div class='gallery-name'>" + gallery['name'] + "</div>"
  return "<div class='gallery-group'>" + nameString + iconsString + "</div>"
};

iconString = function(icon) {
  var img_id = icon["id"];
  var img_url = icon["url"];
  var img_key = icon["keyword"];

  if (!icon['skip_dropdown']) $("#icon_dropdown").append($("<option>").attr({value: img_id}).append(img_key));
  var icon_img = $("<img>").attr({src: img_url, id: img_id, alt: img_key, title: img_key, 'class': 'icon'});
  return $("<div>").attr('class', 'gallery-icon').append(icon_img).append("<br />").append(img_key)[0].outerHTML;
};

tinyMCESetup = function(ed) {
  ed.on('init', function(args) {
    if($("#html").hasClass('selected') == true) {
      tinyMCE.execCommand('mceRemoveEditor', false, 'post_content');
      tinyMCE.execCommand('mceRemoveEditor', false, 'reply_content');
      $(".tinymce").val(gon.original_content); // TODO fix hack
    } else {
      var rawContent = tinymce.activeEditor.getContent({format: 'raw'});
      var content = tinymce.activeEditor.getContent();
      if (rawContent == '<p>&nbsp;<br></p>' && content == '') { tinymce.activeEditor.setContent(''); } // TODO fix hack
    };
  });
};

getAndSetCharacterData = function(characterId, options) {
  var restore_icon = false;
  if (typeof options != 'undefined') {
    if (options['restore_icon']) restore_icon = options['restore_icon'];
  }
  // Handle page interactions
  var selectedIconID = $("#reply_icon_id").val();
  $("#character-selector").hide();
  $("#current-icon-holder").unbind();
  $("#icon_dropdown").empty().append('<option value="">No Icon</option>');

  // Handle special case where just setting to your base account
  if (characterId == '') {
    $("#post-editor .post-character").hide().data('character-id', '');
    $("#post-editor .post-screenname").hide();

    var avatar = gon.current_user.avatar;
    if(avatar && avatar.url != null) {
      var url = avatar.url;
      var aid = avatar.id;
      var keyword = avatar.keyword;
      $("#gallery").html("");
      $("#gallery").append(iconString({id: aid, url: url, keyword: keyword}));
      $("#gallery").append(iconString({id: '', url: '/images/no-icon.png', keyword: 'No Icon', skip_dropdown: true}));
      bindIcon();
      bindGallery();
      if (!restore_icon) setIcon(aid, url, keyword, keyword);
      $("#post-editor #post-author-spacer").show();
    } else {
      $("#post-editor #post-author-spacer").hide();
    }
    if (restore_icon) setIconFromId(selectedIconID);

    return // Don't need to load data from server (TODO combine with below?)
  }

  $.get('/api/v1/characters/' + characterId, {}, function (resp) {
    var character = resp['data'];

    // Display the correct name/screenname fields
    $("#post-editor #post-author-spacer").hide();
    $("#post-editor .post-character").show().html(character['name']).data('character-id', characterId);
    if(character['screenname'] == undefined) {
      $("#post-editor .post-screenname").hide();
    } else {
      $("#post-editor .post-screenname").show().html(character['screenname']);
    }

    // Display no icon if no default set
    if (character['default'] == undefined) {
      $("#current-icon").removeClass('pointer');
      setIcon('');
      return;
    }

    // Display default icon
    $("#current-icon").addClass('pointer');

    // Calculate new galleries
    $("#gallery").html("");
    var galleries = character['galleries'];
    var multiGallery = galleries.length > 1;
    for(var i=0; i<galleries.length; i++) {
      var gallery = galleries[i];
      $("#gallery").append(galleryString(gallery, multiGallery));
    }

    $("#gallery").append(iconString({id: '', url: '/images/no-icon.png', keyword: 'No Icon', skip_dropdown: true}));
    bindGallery();
    bindIcon();
    if (restore_icon)
      setIconFromId(selectedIconID);
    else
      setIcon(character['default']['id'], character['default']['url'], character['default']['keyword'], character['default']['keyword']);
  }, 'json');
};

setIconFromId = function(id, img) {
  // Assumes the #gallery div is populated with icons with the correct values
  if (id == "") return setIcon(id);
  if (typeof(img) === 'undefined') img = $("#"+id);
  setIcon(id, img.attr('src'), img.attr('title'), img.attr('alt'));
};

setIcon = function(id, url, title, alt) {
  // Handle No Icon case
  if (id == "") {
    url = "/images/no-icon.png";
    title = "No Icon";
    alt = "";
  }

  // Hide icon UI elements
  $('#icon-overlay').hide();
  $('#gallery').hide();

  // Set necessary form values
  $("#reply_icon_id").val(id);
  $("#icon_dropdown").val(id);
  $("#current-icon").data('icon-id', id);

  // Set current icon UI elements
  $("#current-icon").attr('src', url);
  $("#current-icon").attr('title', title);
  $("#current-icon").attr('alt', alt);
};

setSections = function() {
  var board_id = $("#post_board_id").val();
  $.get("/api/v1/boards/"+board_id, {}, function(resp) {
    var sections = resp['data']['board_sections'];
    if (sections.length > 0) {
      $("#section").show();
      $("#post_section_id").empty().append('<option value="">— Choose Section —</option>');
      for(var i = 0; i < sections.length; i++) {
        $("#post_section_id").append('<option value="'+sections[i]['id']+'">'+sections[i]['name']+'</option>');
      }
      $("#post_section_id").trigger("change");
    } else {
      $("#post_section_id").val("");
      $("#section").hide();
    }
  }, 'json');
};
