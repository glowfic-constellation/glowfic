/* global gon, tinyMCE */
/* exported setupEditorHelpBox, toggleEditor, setupTinyMCE */

let tinyMCEInit = false;

// Matches values that look like a web address (scheme, "www.", or "domain.tld"),
// used to warn when a URL is typed/pasted into a link's Title (tooltip) field.
const TITLE_URL_PATTERN = /^\s*((https?|ftp):\/\/|www\.|[a-z0-9][a-z0-9-]*\.[a-z]{2,}([/?#]|\s|$))/i;

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
    // warn when a URL is entered into a link's Title field (it only sets a tooltip)
    setup: setupLinkTitleValidation,
  };
}

function setupLinkTitleValidation(editor) {
  editor.on('OpenWindow', function(evt) {
    const dialog = evt.dialog;
    if (!dialog || typeof dialog.getData !== 'function') return;
    if (!isLinkDialogData(dialog.getData())) return;
    // Let the dialog finish rendering before we reach into its DOM.
    window.setTimeout(bindLinkTitleWarning, 0);
  });
}

function isLinkDialogData(data) {
  // The link dialog is the only one exposing both a URL and a Title field.
  if (!data) return false;
  return ('url' in data) && ('title' in data);
}

function bindLinkTitleWarning() {
  const dialogs = document.querySelectorAll('.tox-dialog');
  const dialogEl = dialogs[dialogs.length - 1];
  if (!dialogEl) return;

  const titleInput = findDialogTitleInput(dialogEl);
  if (!titleInput || titleInput.dataset.glowficUrlCheck) return;
  titleInput.dataset.glowficUrlCheck = '1';

  const warning = buildTitleUrlWarning();
  titleInput.parentNode.appendChild(warning);

  const check = function() {
    warning.style.display = TITLE_URL_PATTERN.test(titleInput.value) ? '' : 'none';
  };
  titleInput.addEventListener('input', check);
  check();
}

function findDialogTitleInput(dialogEl) {
  let titleInput = null;
  const groups = dialogEl.querySelectorAll('.tox-form__group');
  groups.forEach(function(group) {
    const label = group.querySelector('.tox-label, label');
    if (label && label.textContent.trim() === 'Title') {
      titleInput = group.querySelector('input, textarea');
    }
  });
  return titleInput;
}

function buildTitleUrlWarning() {
  const warning = document.createElement('div');
  warning.className = 'glowfic-title-url-warning';
  warning.setAttribute('role', 'alert');
  warning.style.color = '#c0392b';
  warning.style.fontSize = '12px';
  warning.style.marginTop = '4px';
  warning.style.display = 'none';
  warning.textContent = 'This looks like a URL. The Title field only sets a hover tooltip — put the web address in the URL field above.';
  return warning;
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
