$(document).ready(function() {
  $("#select-output").click(function () {
    copyToClipboard($("#copy-output"));
    return false;
  });
});

function copyToClipboard(elem) {
    // set up content in hidden textarea
    var currentFocus = document.activeElement;
    var target = document.getElementById("_hiddenCopyText_");
    target.textContent = $.trim(elem.text());
    var end = target.value.length;

    // select the content
    if (target.setSelectionRange) { target.focus(); target.setSelectionRange(0, end); }
    else if (target.createTextRange) { var range = target.createTextRange(); range.collapse(true); range.moveEnd('character', end); range.moveStart('character', 0); range.select(); } /* IE */
    else if (target.selectionStart) { target.selectionStart = 0; target.selectionEnd = end; }

    // copy the selection
    try {
        document.execCommand("copy");
    } catch(e) {}

    // restore original focus
    if (currentFocus && typeof currentFocus.focus === "function") { currentFocus.focus(); }
}
