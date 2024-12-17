//= require writable
/* global gon, createTagSelect, tinyMCEConfig, setupEditorHelpBox, toggleEditor, setupTinyMCE */

createTagSelect("ContentWarning", "content_warning", "user");

$(document).ready(function() {
  setupWritableEditor();
});

function setupWritableEditor() {
  // Only initialize TinyMCE if it's required
  if ($("#rtf").hasClass('selected') === true) {
    setupTinyMCE();
  }

  $('#rtf, #html, #md').click(function() { toggleEditor(this, 'profile_editor_mode', ['user_profile']) });

  setupEditorHelpBox();
}
