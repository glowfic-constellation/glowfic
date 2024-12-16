/* global gon, tinyMCE, createTagSelect */

createTagSelect("ContentWarning", "content_warning", "user");

let tinyMCEInit = false;
let shownIcons = [];
let iconSelectBox;

function tinyMCEConfig(selector) {
  const height = ($(selector).height() || 150) + 15;
  return {
    // integration configs
    selector: selector,
    plugins: ["wordcount", "image", "link", "autoresize"],
    cache_suffix: '?v=7.5.1-2024-11-23',
    license_key: 'gpl',
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
  // if ($("#post-editor .view-button").length > 0) setupWritableEditor();
  setupWritableEditor();
});

function setupWritableEditor() {
  // SET UP WRITABLE EDITOR:
  // TODO: fix hack
  // Only initialize TinyMCE if it's required
  if ($("#rtf").hasClass('selected') === true) {
    setupTinyMCE();
  }

  const editorHelp = $("#editor-help-box");
  const defaultHelpWidth = 500;
  const defaultHelpHeight = 700;
  editorHelp.dialog({
    autoOpen: false,
    title: 'Editor Help',
    width: defaultHelpWidth,
    height: defaultHelpHeight
  });

  $('#rtf, #html, #md').click(toggleEditor);
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
}

function toggleEditor() {
  if (this.id === 'rtf') {
    $("#html").removeClass('selected');
    $("#md").removeClass('selected');
    $("#editor_mode").val('rtf');
    $(this).addClass('selected');
    if (tinyMCEInit) {
      tinyMCE.execCommand('mceAddEditor', true, { id: 'user_profile', options: tinyMCEConfig('#user_profile') });
    } else {
      setupTinyMCE();
    }
  } else if (this.id === 'md') {
    $("#html").removeClass('selected');
    $("#rtf").removeClass('selected');
    $("#editor_mode").val('md');
    $(this).addClass('selected');
    tinyMCE.execCommand('mceRemoveEditor', false, 'user_profile');
  } else if (this.id === 'html') {
    $("#rtf").removeClass('selected');
    $("#md").removeClass('selected');
    $("#editor_mode").val('html');
    $(this).addClass('selected');
    tinyMCE.execCommand('mceRemoveEditor', false, 'user_profile');
  }
}

function setupTinyMCE() {
  const selector = 'textarea.tinymce';
  if (typeof tinyMCE === 'undefined') {
    setTimeout(setupTinyMCE, 50);
  } else {
    tinyMCE.init(tinyMCEConfig(selector));
    tinyMCEInit = true;
  }
}
