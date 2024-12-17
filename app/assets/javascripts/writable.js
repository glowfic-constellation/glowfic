/* global gon, tinyMCE, createTagSelect */

let tinyMCEInit = false;

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

function setupEditorHelpBox() {
  const editorHelp = $("#editor-help-box");
  const defaultHelpWidth = 500;
  const defaultHelpHeight = 700;
  editorHelp.dialog({
    autoOpen: false,
    title: 'Editor Help',
    width: defaultHelpWidth,
    height: defaultHelpHeight
  });

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

function toggleEditor(button, editor_mode_selector_id, mce_editor_ids) {
  if (button.id === 'rtf') {
    $("#html").removeClass('selected');
    $("#md").removeClass('selected');
    $("#" + editor_mode_selector_id).val('rtf');
    $(button).addClass('selected');
    if (tinyMCEInit) {
      for (const mce_editor_id of mce_editor_ids) {
        tinyMCE.execCommand('mceAddEditor', true, { id: mce_editor_id, options: tinyMCEConfig('#' + mce_editor_id) });
      }
    } else {
      setupTinyMCE();
    }
  } else if (button.id === 'md') {
    $("#html").removeClass('selected');
    $("#rtf").removeClass('selected');
    $("#" + editor_mode_selector_id).val('md');
    $(button).addClass('selected');
    for (const mce_editor_id of mce_editor_ids) {
      tinyMCE.execCommand('mceRemoveEditor', false, mce_editor_id);
    }
  } else if (button.id === 'html') {
    $("#rtf").removeClass('selected');
    $("#md").removeClass('selected');
    $("#" + editor_mode_selector_id).val('html');
    $(button).addClass('selected');
    for (const mce_editor_id of mce_editor_ids) {
      tinyMCE.execCommand('mceRemoveEditor', false, mce_editor_id);
    }
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
