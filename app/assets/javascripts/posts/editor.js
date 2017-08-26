/* global gon, tinymce, tinyMCE, resizeScreenname */
var tinyMCEInit = false;

$(document).ready(function() {
  // SET UP POST METADATA EDITOR:

  var PRIVACY_ACCESS = 2; // TODO don't hardcode

  // Adding Select2 UI to relevant selects
  $("#post_board_id").select2({
    width: '200px',
    minimumResultsForSearch: 20
  });

  $("#post_section_id").select2({
    width: '200px',
    minimumResultsForSearch: 20
  });

  $("#post_privacy").select2({
    width: '200px',
    minimumResultsForSearch: 20
  });

  $("#post_viewer_ids").select2({
    width: '200px',
    minimumResultsForSearch: 20,
    placeholder: 'Choose user(s) to view this post'
  });

  createTagSelect("Label", "label");
  createTagSelect("Setting", "setting");
  createTagSelect("ContentWarning", "content_warning");

  if (String($("#post_privacy").val()) !== String(PRIVACY_ACCESS)) {
    $("#access_list").hide();
  }

  if ($("#post_section_id").val() === '') setSections();
  $("#post_board_id").change(function() { setSections(); });

  $("#post_privacy").change(function() {
    if (String($(this).val()) === String(PRIVACY_ACCESS)) {
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

  if ($("#post-editor .view-button").length === 0) return; // Skip if there is no writable editor (no RTF/HTML buttons)

  // SET UP WRITABLE EDITOR:

  // TODO fix hack
  // Hack because having In Thread characters as a group in addition to Template groups
  // duplicates characters in the dropdown, and therefore multiple options are selected
  var selectd;
  $("#active_character option[selected]").each(function() {
    if (!selectd) selectd = this;
    $(this).prop("selected", false);
  });
  $(selectd).prop("selected", true);

  // TODO fix hack
  // Only initialize TinyMCE if it's required
  if ($("#rtf").hasClass('selected') === true) {
    setupTinyMCE();
  }

  // Hack to deal with Firefox's "helpful" caching of form values on soft refresh (now via IDs)
  var selectedCharID = $("#reply_character_id").val();
  var displayCharID = String($("#post-editor .post-character").data('character-id'));
  var selectedIconID = $("#reply_icon_id").val();
  var displayIconID = String($("#current-icon").data('icon-id'));
  var selectedAliasID = $("#reply_character_alias_id").val();
  var displayAliasID = String($("#post-editor .post-character").data('alias-id'));
  if (selectedCharID !== displayCharID) {
    getAndSetCharacterData(selectedCharID, {restore_icon: true, restore_alias: true});
    $("#active_character").val(selectedCharID).trigger("change.select2");
  } else {
    if ($(".gallery-icon").length > 1) { /* Bind icon & gallery only if not resetting character, else it duplicate binds */
      bindIcon();
      bindGallery();
    }
    if (selectedIconID !== displayIconID) {
      setIconFromId(selectedIconID); // Handle the case where just the icon was cached
    }
    if (selectedAliasID !== displayAliasID) {
      var correctName = $("#character_alias option[value="+selectedAliasID+"]").text();
      $("#post-editor .post-character #name").html(correctName);
      $("#post-editor .post-character").data('alias-id', selectedAliasID);
      $("#character_alias").val(selectedAliasID).trigger("change.select2");
    }
  }

  // Set the quick-switcher's selected character
  setCharacterListSelected(selectedCharID);

  // Bind both change() and keyup() in the icon keyword dropdown because Firefox doesn't
  // respect up/down key selections in a dropdown as a valid change() trigger
  $("#icon_dropdown").change(function() { setIconFromId($(this).val()); });
  $("#icon_dropdown").keyup(function() { setIconFromId($(this).val()); });

  $('.view-button').click(function() {
    if (this.id === 'rtf') {
      $("#html").removeClass('selected');
      $("#editor_mode").val('rtf');
      $(this).addClass('selected');
      if (tinyMCEInit) {
        tinyMCE.execCommand('mceAddEditor', true, 'post_content');
        tinyMCE.execCommand('mceAddEditor', true, 'reply_content');
      } else {
        setupTinyMCE();
      }
    } else if (this.id === 'html') {
      $("#rtf").removeClass('selected');
      $("#editor_mode").val('html');
      $(this).addClass('selected');
      tinyMCE.execCommand('mceRemoveEditor', false, 'post_content');
      tinyMCE.execCommand('mceRemoveEditor', false, 'reply_content');
    }
  });

  $("#swap-icon").click(function() {
    $('#character-selector').toggle();
    $('#alias-selector').hide();
    $('html, body').scrollTop($("#post-editor").offset().top);
  });

  $("#swap-alias").click(function() {
    $('#alias-selector').toggle();
    $('#character-selector').hide();
    $('html, body').scrollTop($("#post-editor").offset().top);
  });

  $("#active_character, #character_alias").on('select2:close', function() {
    $('html, body').scrollTop($("#post-editor").offset().top);
  });

  $("#active_character").change(function() {
    // Set the ID
    var id = $(this).val();
    $("#reply_character_id").val(id);
    getAndSetCharacterData(id);
  });

  $(".char-access-icon").click(function() {
    var id = $(this).data('character-id');
    $("#reply_character_id").val(id);
    getAndSetCharacterData(id);
  });

  $("#character_alias").change(function() {
    // Set the ID
    var id = $(this).val();
    $("#reply_character_alias_id").val(id);
    $("#post-editor .post-character #name").html($('#character_alias option:selected').text());
    $('#alias-selector').hide();
    $("#post-editor .post-character").data('alias-id', id);
  });

  // Hides selectors when you hit the escape key
  $(document).bind("keydown", function(e) {
    e = e || window.event;
    var charCode = e.which || e.keyCode;
    if (charCode === 27) {
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

function bindGallery() {
  $("#gallery img").click(function() {
    var id = $(this).attr('id');
    setIconFromId(id, $(this));
  });
}

function bindIcon() {
  $('#current-icon-holder').click(function() {
    $('#icon-overlay').toggle();
    $('#gallery').toggle();
    $('html, body').scrollTop($("#post-editor").offset().top);
  });
}

function galleryString(gallery, multiGallery) {
  var iconsString = "";
  var icons = gallery.icons;

  for (var i=0; i<icons.length; i++) {
    iconsString += iconString(icons[i]);
  }

  if (!multiGallery) return iconsString;

  var nameString = "<div class='gallery-name'>" + gallery.name + "</div>";
  return "<div class='gallery-group'>" + nameString + iconsString + "</div>";
}

function iconString(icon) {
  var imgId = icon.id;
  var imgUrl = icon.url;
  var imgKey = icon.keyword;

  if (!icon.skip_dropdown) $("#icon_dropdown").append($("<option>").attr({value: imgId}).append(imgKey));
  var iconImg = $("<img>").attr({src: imgUrl, id: imgId, alt: imgKey, title: imgKey, 'class': 'icon'});
  return $("<div>").attr('class', 'gallery-icon').append(iconImg).append("<br />").append(imgKey)[0].outerHTML;
}

function setupTinyMCE() {
  if (typeof tinyMCE === 'undefined') {
    setTimeout(arguments.callee, 50);
  } else {
    tinyMCE.init({
      selector: "textarea.tinymce",
      menubar: false,
      toolbar: ["bold italic underline strikethrough | link image | blockquote hr bullist numlist | undo redo"],
      plugins: "image,hr,link,autoresize",
      custom_undo_redo_levels: 10,
      content_css: "/stylesheets/tinymce.css",
      statusbar: true,
      elementpath: false,
      theme_advanced_resizing: true,
      theme_advanced_resize_horizontal: false,
      autoresize_bottom_margin: 15,
      browser_spellcheck: true,
      relative_urls: false,
      remove_script_host: true,
      document_base_url: "https://www.glowfic.com/",
      setup: function(ed) {
        ed.on('init', function() {
          var rawContent = tinymce.activeEditor.getContent({format: 'raw'});
          var content = tinymce.activeEditor.getContent();
          // TODO fix hack
          if (rawContent === '<p>&nbsp;<br></p>' && content === '') {
            tinymce.activeEditor.setContent('');
          }
        });
      }
    });
    tinyMCEInit = true;
  }
}

function getAndSetCharacterData(characterId, options) {
  var restoreIcon = false;
  var restoreAlias = false;
  if (typeof options !== 'undefined') {
    restoreIcon = options.restore_icon;
    restoreAlias = options.restore_alias;
  }

  // Handle page interactions
  var selectedIconID = $("#reply_icon_id").val();
  var selectedAliasID = $("#reply_character_alias_id").val();
  $("#character-selector").hide();
  $("#current-icon-holder").unbind();
  $("#icon_dropdown").empty().append('<option value="">No Icon</option>');

  setCharacterListSelected(characterId);

  // Handle special case where just setting to your base account
  if (characterId === '') {
    $("#post-editor .post-character").hide().data('character-id', '').data('alias-id', '');
    $("#post-editor .post-screenname").hide().html('');

    var avatar = gon.current_user.avatar;
    if (avatar && avatar.url !== null) {
      var url = avatar.url;
      var aid = avatar.id;
      var keyword = avatar.keyword;
      $("#gallery").html("");
      $("#gallery").append(iconString({id: aid, url: url, keyword: keyword}));
      $("#gallery").append(iconString({id: '', url: '/images/no-icon.png', keyword: 'No Icon', skip_dropdown: true}));
      bindIcon();
      bindGallery();
      if (!restoreIcon) setIcon(aid, url, keyword, keyword);
      $("#post-editor #post-author-spacer").show();
    } else {
      if (!restoreIcon) setIcon("");
      $("#post-editor #post-author-spacer").hide();
    }
    if (restoreIcon) setIconFromId(selectedIconID);
    $("#character_alias").val('').trigger("change.select2");
    $("#reply_character_alias_id").val('');

    return; // Don't need to load data from server (TODO combine with below?)
  }

  var postID = $("#reply_post_id").val();
  $.getJSON('/api/v1/characters/' + characterId, {post_id: postID}, function(resp) {
    // Display the correct name/screenname fields
    $("#post-editor #post-author-spacer").hide();
    $("#post-editor .post-character").show().data('character-id', characterId);
    $("#post-editor .post-character #name").html(resp.name);
    var screennameBox = $("#post-editor .post-screenname");
    if (resp.screenname) {
      screennameBox.show().html(resp.screenname);
      resizeScreenname(screennameBox);
    } else {
      screennameBox.hide().html('');
    }

    // Display alias selector if relevant
    if (resp.aliases.length > 0) {
      $("#swap-alias").show();
      $("#character_alias").empty().append($("<option>").attr({value: ''}).append(resp.name));
      for (var i=0; i<resp.aliases.length; i++) {
        $("#character_alias").append($("<option>").attr({value: resp.aliases[i].id}).append(resp.aliases[i].name));
      }
      // Restore active alias, but only if not already restoring an alias
      if (typeof resp.alias_id_for_post !== "undefined" && !restoreAlias) {
        restoreAlias = true;
        selectedAliasID = resp.alias_id_for_post;
        $("#reply_character_alias_id").val(selectedAliasID);
      }
    } else {
      $("#swap-alias").hide();
    }

    if (restoreAlias && selectedAliasID) {
      var correctName = $("#character_alias option[value="+selectedAliasID+"]").text();
      $("#post-editor .post-character #name").html(correctName);
      $("#post-editor .post-character").data('alias-id', selectedAliasID);
      $("#character_alias").val(selectedAliasID).trigger("change.select2");
    } else {
      $("#post-editor .post-character").data('alias-id', '');
      $("#character_alias").val('').trigger("change.select2");
      $("#reply_character_alias_id").val('');
    }

    $("#gallery").html('');

    // Display no icon if no default set
    if (!resp.default) {
      setIcon('');
      // Remove pointer and skip galleries if no galleries attached to character
      if (resp.galleries.length === 0) {
        $("#current-icon").removeClass('pointer');
        return;
      }
    }

    // Display default icon
    $("#current-icon").addClass('pointer');

    // Calculate new galleries
    var multiGallery = resp.galleries.length > 1;
    for (var j = 0; j < resp.galleries.length; j++) {
      $("#gallery").append(galleryString(resp.galleries[j], multiGallery));
    }

    $("#gallery").append(iconString({id: '', url: '/images/no-icon.png', keyword: 'No Icon', skip_dropdown: true}));
    bindGallery();
    bindIcon();
    if (restoreIcon)
      setIconFromId(selectedIconID);
    else
      setIcon(resp.default.id, resp.default.url, resp.default.keyword, resp.default.keyword);
  });
}

function setIconFromId(id, img) {
  // Assumes the #gallery div is populated with icons with the correct values
  if (id === "") return setIcon(id);
  if (typeof img === 'undefined') img = $("#"+id);
  return setIcon(id, img.attr('src'), img.attr('title'), img.attr('alt'));
}

function setIcon(id, url, title, alt) {
  // Handle No Icon case
  if (id === "") {
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
}

function setSections() {
  var boardId = $("#post_board_id").val();
  $.get("/api/v1/boards/"+boardId, {}, function(resp) {
    var sections = resp.board_sections;
    if (sections.length > 0) {
      $("#section").show();
      $("#post_section_id").empty().append('<option value="">— Choose Section —</option>');
      for (var i = 0; i < sections.length; i++) {
        $("#post_section_id").append($("<option>").attr({value: sections[i].id}).append(sections[i].name));
      }
      $("#post_section_id").trigger("change.select2");
    } else {
      $("#post_section_id").val("").trigger("change.select2");
      $("#section").hide();
    }
  }, 'json');
}

function createTagSelect(tagType, selector) {
  $("#post_"+selector+"_ids").select2({
    tags: true,
    tokenSeparators: [','],
    placeholder: 'Enter ' + selector.replace('_', ' ') + '(s) separated by commas',
    ajax: {
      delay: 200,
      url: '/api/v1/tags',
      dataType: 'json',
      data: function(params) {
        var data = {
          q: params.term,
          t: tagType,
          page: params.page
        };
        return data;
      },
      processResults: function(data, params) {
        params.page = params.page || 1;
        var total = this._request.getResponseHeader('Total');
        return {
          results: data.results,
          pagination: {
            more: (params.page * 25) < total
          }
        };
      },
      cache: true
    },
    createTag: function(params) {
      var term = $.trim(params.term);
      if (term === '') return null;

      return {
        id: '_' + term,
        text: term
      };
    },
    width: '300px'
  });
}

function setCharacterListSelected(characterId) {
  $(".char-access-icon.semiopaque").removeClass('semiopaque').addClass('pointer');
  $(".char-access-icon").each(function() {
    if (String($(this).data('character-id')) === String(characterId)) $(this).addClass('semiopaque').removeClass('pointer');
  });
}
