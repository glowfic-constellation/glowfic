//= require posts/edit_notes
/* global gon, tinyMCE, resizeScreenname, createTagSelect, createSelect2 */

let tinyMCEInit = false;
let shownIcons = [];
let iconSelectBox;

function tinyMCEConfig(selector) {
  const height = ($(selector).height() || 150) + 15;
  return {
    // integration configs
    selector: selector,
    plugins: ["wordcount", "image", "link", "autoresize"],
    cache_suffix: '?v=6.8.2',
    // interface configs
    menubar: false, // disable "File", "Edit", etc
    contextmenu: false,
    min_height: height,
    // - toolbar
    toolbar_sticky: true,
    toolbar: ["bold italic underline strikethrough forecolor | link image | blockquote hr bullist numlist | undo redo"],
    // - statusbar
    statusbar: true,
    branding: false,
    elementpath: false,
    resize: true,
    // editor content behavior
    body_class: gon.editor_class,
    custom_undo_redo_levels: 10,
    content_css: gon.tinymce_css_path,
    browser_spellcheck: true,
    document_base_url: gon.base_url,
    relative_urls: false,
    remove_script_host: true,
    text_patterns: false, // disable markdown-like autoformatting from TinyMCE 6 (for now)
    // plugin configs
    // - autoresize
    autoresize_bottom_margin: 5,
  };
}

$(document).ready(function() {
  setupMetadataEditor();
  iconSelectBox = $('#reply-icon-selector');

  if ($("#post-editor .view-button").length > 0) setupWritableEditor();
});

function setupMetadataEditor() {
  // Adding Select2 UI to relevant selects
  createSelect2('#post_board_id', {
    width: '200px',
    minimumResultsForSearch: 20
  });

  createSelect2('#post_section_id', {
    width: '200px',
    minimumResultsForSearch: 20
  });

  createSelect2('#post_privacy', {
    width: '200px',
    minimumResultsForSearch: 20
  });

  createSelect2('#post_viewer_ids', {
    width: '200px',
    minimumResultsForSearch: 20,
    placeholder: 'Choose user(s) to view this post'
  });

  createSelect2('#post_unjoined_author_ids', {
    width: '300px',
    minimumResultsForSearch: 20,
    placeholder: 'Choose user(s) to invite to reply to this post'
  });

  createSelect2('#active_npc', {
    tags: true,
    // https://select2.org/dropdown#templating
    templateResult: function(state) {
      // used to show "Create new:" before new NPC entries
      if (!state.element) return "Create New: " + state.text;
      return state.text;
    },
    createTag: function(params) {
      // used to remove ID (defaults to params.term, but then we try doing an API lookup)
      return { id: "new", text: params.term };
    }
  });

  createTagSelect("Label", "label", "post");
  createTagSelect("Setting", "setting", "post");
  createTagSelect("ContentWarning", "content_warning", "post");

  if ($("#post_privacy").val() !== 'access_list') {
    $("#access_list").hide();
  }

  if ($("#post_section_id").val() === '') setSections();
  $("#post_board_id").change(function() { setSections(); });

  $("#post_privacy").change(function() {
    if ($(this).val() === 'access_list') {
      $("#access_list").show();
    } else {
      $("#access_list").hide();
    }
  });

  $("#post_unjoined_author_ids").change(function() {
    const numAuthors = $("#post_unjoined_author_ids :selected").length;
    $("#post_authors_locked").prop('checked', (numAuthors > 0));
  });
}

function setupWritableEditor() {
  $('.post-editor-expander').click(function() {
    $(this).children(".info").hide();
    $(this).children(".hidden").show();
  });

  // SET UP WRITABLE EDITOR:

  // TODO fix hack
  // Hack because having In Thread characters as a group in addition to Template groups
  // duplicates characters in the dropdown, and therefore multiple options are selected
  let selectd;
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

  fixWritableFormCaching();

  // Bind both change() and keyup() in the icon keyword dropdown because Firefox doesn't
  // respect up/down key selections in a dropdown as a valid change() trigger
  $("#icon_dropdown").change(function() { setIconFromId($(this).val()); });
  $("#icon_dropdown").keyup(function() { setIconFromId($(this).val()); });

  const editorHelp = $("#editor-help-box");
  const defaultHelpWidth = 500;
  const defaultHelpHeight = 700;
  editorHelp.dialog({
    autoOpen: false,
    title: 'Editor Help',
    width: defaultHelpWidth,
    height: defaultHelpHeight
  });

  $('#rtf, #html').click(toggleEditor);
  $('#editor-help').click(function() {
    if (editorHelp.dialog('isOpen')) {
      editorHelp.dialog('close');
    } else {
      const width = Math.min($(window).width()-20, defaultHelpWidth);
      const height = Math.min($(window).height()-20, defaultHelpHeight);
      editorHelp.dialog('option', {width: width, height: height}).dialog('open');
      editorHelp.dialog('open');
    }
  });

  $("#swap-character").click(function() {
    $('#character-selector').toggle();
    $('#alias-selector').hide();
    $('html, body').scrollTop($("#post-editor").offset().top);
  });

  $("#swap-alias").click(function() {
    $('#alias-selector').toggle();
    $('#character-selector').hide();
    $('html, body').scrollTop($("#post-editor").offset().top);
  });

  $("#active_character, #active_npc, #character_alias").on('select2:close', function() {
    $('html, body').scrollTop($("#post-editor").offset().top);
  });

  $("#active_character").change(function() {
    const id = $(this).val();
    $("#reply_character_id").val(id);
    getAndSetCharacterData({ id: id });
  });

  $("#active_npc").change(function() {
    let id = $(this).val();
    const item = $("option:selected", this);
    let name = item.text();
    if (id === "") name = "NPC"; // placeholder corresponds to a basic "NPC" user
    if (id === "new") id = "";
    $("#reply_character_id").val(id);
    getAndSetCharacterData({ id: id, name: name, npc: true });
  });

  $(".char-access-icon").click(function() {
    const id = $(this).data('character-id');
    $("#reply_character_id").val(id);
    getAndSetCharacterData({ id: id }, { updateCharDropdowns: true });
  });

  $("#character_alias").change(function() {
    const id = $(this).val();
    $("#reply_character_alias_id").val(id);
    $("#post-editor .post-character #name").text($('#character_alias option:selected').text());
    $('#alias-selector').hide();
    $("#post-editor .post-character").data('alias-id', id);
  });

  $('#select-character, #select-npc').click(toggleNPC);

  // Hides selectors when you hit the escape key
  $(document).bind("keydown", function(e) {
    e = e || window.event;
    const charCode = e.which || e.keyCode;
    if (charCode === 27) {
      $('#icon-overlay').hide();
      iconSelectBox.hide();
      $('#character-selector').hide();
    }
  });

  // Hides selectors when you click outside them
  $(document).click(function(e) {
    const target = e.target;
    hideSelect(target, iconSelectBox, '#current-icon-holder');
    hideSelect(target, $('#character-selector'), '#swap-character');
    hideSelect(target, $('#alias-selector'), '#swap-alias');
  });
}

function hideSelect(target, selectBox, selectHolder) {
  if (!$(target).closest(selectHolder).length && !$(target).closest(selectBox).length && !$(target).closest(".select2-container").length) {
    if (selectHolder === '#current-icon-holder') { $('#icon-overlay').hide(); }
    selectBox.hide();
  }
}

function fixWritableFormCaching() {
  // Hack to deal with Firefox's "helpful" caching of form values on soft refresh (now via IDs)
  const isNPC = $("#character_npc").val() === "true";
  const selectedNPC = $("#character_name").val();
  const selectedCharID = $("#reply_character_id").val();
  const displayCharID = String($("#post-editor .post-character").data('character-id'));
  const selectedIconID = $("#reply_icon_id").val();
  // const displayIconID = String($("#current-icon").data('icon-id'));
  const selectedAliasID = $("#reply_character_alias_id").val();
  // const displayAliasID = String($("#post-editor .post-character").data('alias-id'));
  if (selectedCharID === displayCharID) {
    if ($(".gallery-icon").length > 1) { /* Bind icon & gallery only if not resetting character, else it duplicate binds */
      bindIcon();
      bindGallery();
    }
    setNPC(selectedNPC, isNPC);
    setIconFromId(selectedIconID); // Handle the case where just the icon was cached
    setAliasFromID(selectedAliasID);
  } else {
    getAndSetCharacterData({ id: selectedCharID, npc: isNPC, name: selectedNPC }, { restore_icon: true, restore_alias: true, updateCharDropdowns: true });
  }

  // Set the quick-switcher's selected character
  setSwitcherListSelected(selectedCharID);
}

function toggleEditor() {
  if (this.id === 'rtf') {
    $("#html").removeClass('selected');
    $("#editor_mode").val('rtf');
    $(this).addClass('selected');
    if (tinyMCEInit) {
      tinyMCE.execCommand('mceAddEditor', true, { id: 'post_content', options: tinyMCEConfig('#post_content') });
      tinyMCE.execCommand('mceAddEditor', true, { id: 'reply_content', options: tinyMCEConfig('#reply_content') });
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
}

function bindGallery() {
  iconSelectBox.find('img').click(function() {
    const id = $(this).data('icon-id');
    setIconFromId(id, $(this));
  });
}

function bindIcon() {
  $('#current-icon-holder').click(function() {
    $('#icon-overlay').toggle();
    iconSelectBox.toggle();
    $('html, body').scrollTop($("#post-editor").offset().top);
  });
}

function galleryNode(gallery, multiGallery) {
  const iconNodes = [];
  const icons = gallery.icons;

  for (let i=0; i<icons.length; i++) {
    iconNodes.push(iconNode(icons[i]));
  }

  if (!multiGallery) return iconNodes;

  const nameNode = $("<div class='gallery-name'></div>").text(gallery.name);
  return $("<div class='gallery-group'></div>").append(nameNode).append(iconNodes);
}

function iconNode(icon) {
  const imgId = icon.id;
  const imgUrl = icon.url;
  const imgKey = icon.keyword;
  shownIcons.push(icon.id);

  if (!icon.skip_dropdown) $("#icon_dropdown").append($("<option>").attr({value: imgId}).text(imgKey));
  const iconImg = $("<img>").attr({src: imgUrl, alt: imgKey, title: imgKey, 'class': 'icon img-'+imgId, 'data-icon-id': imgId});
  return $("<div>").attr('class', 'gallery-icon').append(iconImg).append("<br />").append(document.createTextNode(imgKey));
}

function setupTinyMCE() {
  const selector = 'textarea.tinymce';
  if (typeof tinyMCE === 'undefined') {
    setTimeout(arguments.callee, 50);
  } else {
    tinyMCE.init(tinyMCEConfig(selector));
    tinyMCEInit = true;
  }
}

// eslint-disable-next-line complexity
function setFormData(characterId, resp, options) {
  let restoreIcon = false;
  let restoreAlias = false;
  let hideCharacterSelect = true;
  let updateCharDropdowns = false;

  if (typeof options !== 'undefined') {
    restoreIcon = options.restore_icon;
    restoreAlias = options.restore_alias;
    hideCharacterSelect = options.hideCharacterSelect;
    updateCharDropdowns = options.updateCharDropdowns;
  }

  setSwitcherListSelected(characterId);

  const selectedIconID = $("#reply_icon_id").val();
  const selectedAliasID = $("#reply_character_alias_id").val();
  if (hideCharacterSelect) $("#character-selector").hide();

  setInfoBoxFields(characterId, resp.name, resp.screenname);
  setNPC(resp.name, resp.npc);

  setAliases(resp.aliases, resp.name);
  setAliasFromID('');
  if (restoreAlias) {
    setAliasFromID(selectedAliasID);
  } else if (resp.alias_id_for_post) {
    setAliasFromID(resp.alias_id_for_post);
  }

  setGalleriesAndDefault(resp.galleries, resp.default_icon);
  setIcon('');
  if (restoreIcon) {
    setIconFromId(selectedIconID);
  } else if (resp.default_icon) {
    setIcon(resp.default_icon.id, resp.default_icon.url, resp.default_icon.keyword, resp.default_icon.keyword);
  }

  if (updateCharDropdowns) updateCharDropdown(characterId, resp.npc);
}

function setInfoBoxFields(characterId, name, screenname) {
  // Display the correct name/screenname fields
  const spacer = $("#post-editor #post-author-spacer");
  const characterNameBox = $("#post-editor .post-character");
  if (name) {
    spacer.hide();
    characterNameBox.show();
  } else {
    spacer.show();
    characterNameBox.hide();
  }
  characterNameBox.data('character-id', characterId);
  $("#post-editor .post-character #name").html(name);

  const screennameBox = $("#post-editor .post-screenname");
  if (screenname) {
    screennameBox.show().html(screenname);
    resizeScreenname(screennameBox);
  } else {
    screennameBox.hide().html(screenname);
  }
}

function setAliases(aliases, name) {
  // Display alias selector if relevant
  const aliasList = $("#character_alias");
  aliasList.empty();
  aliasList.append($("<option>").attr({value: ''}).text(name));
  if (aliases.length > 0) {
    $("#swap-alias").show();
    for (let i=0; i<aliases.length; i++) {
      aliasList.append($("<option>").attr({value: aliases[i].id}).text(aliases[i].name));
    }
  } else {
    $("#swap-alias").hide();
  }
}

function setAliasFromID(selectedAliasID) {
  const correctName = $("#character_alias option[value=\""+selectedAliasID+"\"]").text();
  $("#post-editor .post-character #name").text(correctName);
  $("#post-editor .post-character").data('alias-id', selectedAliasID);
  $("#character_alias").val(selectedAliasID).trigger("change.select2");
  $("#reply_character_alias_id").val(selectedAliasID);
}

// eslint-disable-next-line complexity
function setGalleriesAndDefault(galleries, defaultIcon) {
  shownIcons = [];

  $("#current-icon-holder").unbind();
  $("#icon_dropdown").empty().append('<option value="">No Icon</option>');

  iconSelectBox.html('');

  // Remove pointer and skip galleries if no galleries attached to character
  if (galleries.length === 0 && !defaultIcon) {
    $("#current-icon").removeClass('pointer');
    return;
  }

  // Display default icon
  $("#current-icon").addClass('pointer');

  // Calculate new galleries
  setGalleries(galleries);

  if (defaultIcon && shownIcons.indexOf(defaultIcon.id) < 0) { iconSelectBox.append(iconNode(defaultIcon)); }

  // If no default and no icons in any galleries, remove pointer
  if (!defaultIcon && shownIcons.length === 0) {
    $("#current-icon").removeClass('pointer');
    return;
  }

  iconSelectBox.append(iconNode({id: '', url: gon.no_icon_path, keyword: 'No Icon', skip_dropdown: true}));
  bindGallery();
  bindIcon();
}

function setGalleries(galleries) {
  const multiGallery = galleries.length > 1;
  for (let j = 0; j < galleries.length; j++) {
    iconSelectBox.append(galleryNode(galleries[j], multiGallery));
  }
}

function getAndSetCharacterData(character, options) {
  // Handle page interactions

  // Handle special case where setting to your base account or a new NPC (no ID)
  if (character.id === '') {
    const avatar = gon.editor_user.avatar;
    const data = {aliases: [], galleries: [], npc: character.npc, name: character.name};
    if (avatar) {
      data.default_icon = avatar;
      data.galleries.push({icons: [avatar]});
    }
    setFormData(character.id, data, options);
    return; // Don't need to load data from server
  }

  const postID = $("#reply_post_id").val();
  $.authenticatedGet('/api/v1/characters/' + character.id, { post_id: postID }, function(resp) {
    setFormData(character.id, resp, options);
  });
}

function setIconFromId(id, img) {
  // Assumes the icon selection box is populated with icons with the correct values
  if (id === "") return setIcon(id);
  if (typeof img === 'undefined') img = $('.img-'+id);
  return setIcon(id, img.attr('src'), img.attr('title'), img.attr('alt'));
}

function setIcon(id, url, title, alt) {
  // Handle No Icon case
  if (id === "") {
    url = gon.no_icon_path;
    title = "No Icon";
    alt = "";
  }

  // Hide icon UI elements
  $('#icon-overlay').hide();
  iconSelectBox.hide();

  // Set necessary form values
  $("#reply_icon_id").val(id);
  $("#icon_dropdown").val(id);
  $("#current-icon").data('icon-id', id);

  // Set current icon UI elements
  $("#current-icon").attr('src', url);
  $("#current-icon").attr('title', title);
  $("#current-icon").attr('alt', alt);
}

function toggleNPC() {
  const isNPC = this.id === "select-npc";
  $("#reply_character_id").val("");
  if (!isNPC) {
    $("#reply_character_id").val("");
    getAndSetCharacterData({ id: "", npc: false, name: "" }, { hideCharacterSelect: false, updateCharDropdowns: true });
    return;
  }

  getAndSetCharacterData({ id: "", npc: true, name: "NPC" }, { hideCharacterSelect: false, updateCharDropdowns: true });
}

function setNPC(name, isNPC) {
  $("#select-npc").toggleClass("selected", isNPC);
  $("#select-character").toggleClass("selected", !isNPC);
  $("#swap-character-character").toggleClass("hidden", isNPC);
  $("#swap-character-npc").toggleClass("hidden", !isNPC);

  $("#character_npc").val(isNPC);
  $("#character_name").val(name);
  $("#post-editor .post-character #name").text(name);
}

function updateCharDropdown(id, isNPC) {
  if (isNPC) {
    $("#active_character").val("");
    $("#active_npc").val(id).trigger('change.select2');
  } else {
    $("#active_npc").val("");
    $("#active_character").val(id).trigger('change.select2');
  }
}

function setSections() {
  const boardId = $("#post_board_id").val();
  $.authenticatedGet("/api/v1/boards/"+boardId, {}, function(resp) {
    const sections = resp.board_sections;
    if (sections.length > 0) {
      $("#section").show();
      $("#post_section_id").empty().append('<option value="">— Choose Section —</option>');
      for (let i = 0; i < sections.length; i++) {
        $("#post_section_id").append($("<option>").attr({value: sections[i].id}).text(sections[i].name));
      }
      $("#post_section_id").trigger("change.select2");
    } else {
      $("#post_section_id").val("").trigger("change.select2");
      $("#section").hide();
    }
  }, 'json');
}

function setSwitcherListSelected(characterId) {
  // for quick selector
  $(".char-access-icon.semiopaque").removeClass('semiopaque').addClass('pointer');
  $(".char-access-icon").each(function() {
    if (String($(this).data('character-id')) === String(characterId)) $(this).addClass('semiopaque').removeClass('pointer');
  });
}
