const originalValues = {};
const originalPublicCheckboxes = {};

$(document).ready(function() {
  const textFields = $(`.bookmark-name-text-field`);
  for (const textField of textFields) {
    originalValues[textField.dataset.bookmarkId] = $(textField).val();
  }
  const checkBoxes = $(`.bookmark-public-checkbox`);
  for (const checkBox of checkBoxes) {
    originalPublicCheckboxes[checkBox.dataset.bookmarkId] = $(checkBox).prop("checked");
  }

  if (!$(".edit-bookmark").length) return;

  $(".edit-bookmark").click(function() {
    /* Button to rename a bookmark */
    const bookmarkId = this.dataset.bookmarkId;
    const editors = $(`.bookmark-editor`);
    for (const editor of editors) {
      // Hide all editors other than the one clicked
      const editorId = editor.dataset.bookmarkId;
      if (editorId === bookmarkId) {
        continue;
      }

      $(editor).hide();
      $(`.bookmark-name[data-bookmark-id="${editorId}"]`).show();
    }

    // Toggle the one clicked
    $(`.bookmark-name[data-bookmark-id="${bookmarkId}"]`).toggle();
    $(`.bookmark-editor[data-bookmark-id="${bookmarkId}"]`).toggle();
    return false;
  });

  $(".save-bookmark").click(function() {
    $(".loading").show();

    const bookmarkId = this.dataset.bookmarkId;
    const newName = $(`.bookmark-name-text-field[data-bookmark-id="${bookmarkId}"]`).val();
    const newPublic = $(`.bookmark-public-checkbox[data-bookmark-id="${bookmarkId}"]`).prop("checked");

    $.authenticatedAjax({
      url: '/api/v1/bookmarks/'+bookmarkId,
      type: 'PATCH',
      data: {'name': newName, 'public': newPublic},
      success: function(data) {
        originalValues[bookmarkId] = newName;
        originalPublicCheckboxes[bookmarkId] = newPublic;
        $(".loading").hide();
        $(`.bookmark-name[data-bookmark-id="${bookmarkId}"] span`).first().html(nameFromData(data.name));
        $(`.bookmark-editor[data-bookmark-id="${bookmarkId}"]`).hide();
        $(`.bookmark-name[data-bookmark-id="${bookmarkId}"]`).show();
        $(`.saveconf[data-bookmark-id="${bookmarkId}"]`).show().delay(2000).fadeOut();
      },
      error: function() {
        $(".loading").hide();
        $(`.saveerror[data-bookmark-id="${bookmarkId}"]`).show();
      }
    });

    return false;
  });

  $(".discard-bookmark-changes").click(function() {
    const bookmarkId = this.dataset.bookmarkId;
    if (confirm('Are you sure you wish to discard your changes?')) {
      $(`.bookmark-name-text-field[data-bookmark-id="${bookmarkId}"]`).val(originalValues[bookmarkId]);
      $(`.bookmark-public-checkbox[data-bookmark-id="${bookmarkId}"]`).prop("checked", originalPublicCheckboxes[bookmarkId]);
    }
    return false;
  });
});

function nameFromData(name) {
  if (name) {
    return $("<b>").text(name);
  }
  return $("<em>").html("(Unnamed)");
}
