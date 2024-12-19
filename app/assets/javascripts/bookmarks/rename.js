let originalValues = {};
let submittedButton = '';

$(document).ready(function() {
  const textFields = $(`.bookmark-name-text-field`);
  for (const textField of textFields) {
    originalValues[textField.dataset.bookmarkId] = $(textField).val();
  }

  if (!$(".rename-bookmark").length) return;

  $(".rename-bookmark").click(function() {
    /* Button to rename a bookmark */
    const bookmarkId = this.dataset.bookmarkId;
    const editors = $(`.bookmark-name-editor`);
    for (const editor of editors) {
      // Hide all editors other than the one clicked
      const editorId = editor.dataset.bookmarkId;
      if (editorId == bookmarkId) {
        continue;
      }

      $(editor).hide();
      $(`.bookmark-name[data-bookmark-id="${editorId}"]`).show();
    }

    // Toggle the one clicked
    $(`.bookmark-name[data-bookmark-id="${bookmarkId}"]`).toggle();
    $(`.bookmark-name-editor[data-bookmark-id="${bookmarkId}"]`).toggle();
    return false;
  });

  $(".save-bookmark-name").click(function() {
    $(".loading").show(); // TODO

    const bookmarkId = this.dataset.bookmarkId;
    const newName = $(`.bookmark-name-text-field[data-bookmark-id="${bookmarkId}"]`).val();

    $.authenticatedAjax({
      url: '/api/v1/bookmarks/'+bookmarkId,
      type: 'PATCH',
      data: {'name': newName},
      success: function(data) {
        originalValues[bookmarkId] = newName;
        $(".loading").hide();
        $(`.bookmark-name[data-bookmark-id="${bookmarkId}"] span`).first().html(nameFromData(newName, data.name));
        $(`.bookmark-name-editor[data-bookmark-id="${bookmarkId}"]`).hide();
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

  $(".discard-bookmark-name").click(function() {
    const bookmarkId = this.dataset.bookmarkId;
    if (confirm('Are you sure you wish to discard your changes?')) {
      $(`.bookmark-name-text-field[data-bookmark-id="${bookmarkId}"]`).val(originalValues[bookmarkId]);
    }
    return false;
  });
});

function nameFromData(name, encodedName) {
  if (name) {
    let div = document.createElement('div');
    div.innerHTML = decodeURI(encodedName);
    return $("<b>").html(div.innerText);
  }
  return $("<em>").html("(Unnamed)");
}
