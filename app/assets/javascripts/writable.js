/* global gon, tinyMCE */
/* exported setupEditorHelpBox, toggleEditor, setupTinyMCE */

let tinyMCEInit = false;

function tinyMCEConfig(selector) {
  const height = ($(selector).height() || 150) + 15;
  return {
    // integration configs
    selector: selector,
    plugins: ["wordcount", "image", "link", "autoresize"],
    cache_suffix: '?v=7.6.1-2025-02-01',
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

function toggleEditor(button, editorModeSelectorID, mceEditorIDs) {
  /* Toggle the editor mode depending on which editor button was clicked. */
  const clickedEditorMode = button.id;

  // Unselect all editor modes that were not the one clicked
  for (const editorMode of ['html', 'md', 'rtf']) {
    if (editorMode === clickedEditorMode) {
      continue;
    }

    $("#" + editorMode).removeClass('selected');
  }

  // Select the clicked editor mode and update the hidden form field with the appropriate value
  $(button).addClass('selected');
  $("#" + editorModeSelectorID).val(clickedEditorMode);

  // Enable or disable the tinyMCE editor depending on the editor mode selected
  if (clickedEditorMode === 'rtf') {
    if (tinyMCEInit) {
      for (const mceEditorID of mceEditorIDs) {
        tinyMCE.execCommand('mceAddEditor', true, { id: mceEditorID, options: tinyMCEConfig('#' + mceEditorID) });
      }
    } else {
      setupTinyMCE();
    }
  } else {
    for (const mceEditorID of mceEditorIDs) {
      tinyMCE.execCommand('mceRemoveEditor', false, mceEditorID);
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
