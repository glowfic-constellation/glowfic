$(document).ready(function() {
  $("#select-output").click(function() {
    copyToClipboard($("#copy-output"));
    return false;
  });
});

function copyToClipboard(elem) {
  // set up content in hidden textarea
  const currentFocus = document.activeElement;
  const inserted = $("<textarea id='_hiddenCopyText_'>").insertAfter(elem);
  const target = inserted[0]; // must be DOM not JQuery object for select range functions
  target.textContent = $.trim(elem.text());

  // select the content
  selectContent(target);

  // copy the selection
  try {
    document.execCommand("copy");
  } catch (e) { /* continue regardless */ }

  // clean up page
  if (currentFocus && typeof currentFocus.focus === "function") { currentFocus.focus(); }
  inserted.remove();
}

function selectContent(target) {
  const end = target.value.length;
  if (target.setSelectionRange) {
    target.focus(); target.setSelectionRange(0, end);
  } else if (target.createTextRange) { /* IE */
    const range = target.createTextRange();
    range.collapse(true);
    range.moveEnd('character', end);
    range.moveStart('character', 0);
    range.select();
  } else if (target.selectionStart) {
    target.selectionStart = 0;
    target.selectionEnd = end;
  }
}
