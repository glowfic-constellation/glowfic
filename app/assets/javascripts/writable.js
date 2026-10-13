/* global gon, tinyMCE */
/* exported setupEditorHelpBox, toggleEditor, setupTinyMCE */

let tinyMCEInit = false;

// The link dialog's Title field only sets a hover tooltip, but people sometimes paste the
// web address into it by mistake; flag values that look like one (scheme, "www.", "domain.tld").
const URL_LIKE_PATTERN = /^\s*((https?|ftp):\/\/|www\.|[a-z0-9][a-z0-9-]*\.[a-z]{2,}([/?#]|\s|$))/i;
const TITLE_URL_MESSAGE = 'This looks like a URL. The Title field only sets a hover tooltip — put the web address in the URL field above.';

function tinyMCEConfig(selector) {
  const height = ($(selector).height() || 150) + 15;
  return {
    // integration configs
    selector: selector,
    plugins: ["wordcount", "image", "link", "autoresize"],
    cache_suffix: '?v=7.8.0-2025-05-11',
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
    setup: setupLinkTitleWarning,
  };
}

function setupLinkTitleWarning(editor) {
  editor.on('OpenWindow', function(evt) {
    // Only the link dialog has both a URL field and a Title field.
    const data = evt.dialog.getData ? evt.dialog.getData() : {};
    if (!('url' in data && 'title' in data)) return;
    const titleInput = findDialogField('Title');
    if (titleInput) warnWhenMatching(titleInput, URL_LIKE_PATTERN, TITLE_URL_MESSAGE);
  });
}

// Finds the form control labelled `labelText` in the most recently opened TinyMCE dialog.
function findDialogField(labelText) {
  const dialog = Array.from(document.querySelectorAll('.tox-dialog')).pop();
  const labels = dialog ? Array.from(dialog.querySelectorAll('label')) : [];
  const label = labels.find(el => el.textContent.trim() === labelText);
  return label ? label.control : null;
}

// Shows `message` beneath `input` for as long as its value matches `pattern`.
function warnWhenMatching(input, pattern, message) {
  const warning = document.createElement('div');
  warning.className = 'field-warning';
  warning.setAttribute('role', 'alert');
  warning.textContent = message;
  input.after(warning);

  const update = () => { warning.hidden = !pattern.test(input.value); };
  input.addEventListener('input', update);
  update();
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
