$(document).ready(function() {
  $("#select-output").click(function() {
    copyToClipboard($("#copy-output"));
    return false;
  });
});

function copyToClipboard(elem) {
  // set up content in hidden textarea
  var currentFocus = document.activeElement;
  var inserted = $("<textarea id='_hiddenCopyText_'>").insertAfter(elem);
  var target = inserted[0]; // must be DOM not JQuery object for select range functions
  target.textContent = $.trim(elem.text());
  var end = target.value.length;

  // select the content
  if (target.setSelectionRange) {
    target.focus(); target.setSelectionRange(0, end);
  } else if (target.createTextRange) { /* IE */
    var range = target.createTextRange();
    range.collapse(true);
    range.moveEnd('character', end);
    range.moveStart('character', 0);
    range.select();
  } else if (target.selectionStart) {
    target.selectionStart = 0;
    target.selectionEnd = end;
  }

  // copy the selection
  try {
    document.execCommand("copy");
  } catch (e) { /* continue regardless */ }

  // clean up page
  if (currentFocus && typeof currentFocus.focus === "function") { currentFocus.focus(); }
  inserted.remove();
}
