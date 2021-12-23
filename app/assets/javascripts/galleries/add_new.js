/* global deleteUnusedIcons */
/* exported addUploadedIcon, addCallback, failCallback */

var done = 0;
var total = 0;
var failed = 0;

$(document).ready(function() {
  fixButtons();
  $(".icon-row td:has(input)").each(function() {
    $(this).keydown(function(event) {
      if (event.which < 37 || event.which > 40) { return; } // skip if not a directional key
      var input = $('input', this);
      if (input.get(0).type !== 'text') { return; } // skip if not text
      if (input.get(0).selectionStart !== input.get(0).selectionEnd) { return; } // skip processing if user has text selected
      processDirectionalKey(event, input);
    });
  });
});

function processDirectionalKey(event, input) {
  var keyLeft = 37,
    keyUp = 38,
    keyRight = 39,
    keyDown = 40;
  var caret = input.get(0).selectionStart;
  var index = $(this).closest('td').index();

  var consume = false;
  switch (event.which) {
  case keyLeft:
    consume = processKeyLeft(caret);
    break;
  case keyRight:
    consume = processKeyRight(caret, input.val().length);
    break;
  case keyUp:
    $(this).closest('tr').prev('.icon-row').children().eq(index).find('input').focus();
    consume = true;
    break;
  case keyDown:
    $(this).closest('tr').next('.icon-row').children().eq(index).find('input').focus();
    consume = true;
    break;
  }
  if (consume) event.preventDefault();
}

function processKeyLeft(caret) {
  if (caret !== 0) { return false; }
  $(this).closest('td').prev().find('input').focus();
  return true;
}

function processKeyRight(caret, length) {
  if (caret <= length) { return false; }
  $(this).closest('td').next().find('input').focus();
  return true;
}

function fixButtons() {
  $(".icon-row-add").hide().unbind();
  $(".icon-row-add").last().show();
  $(".icon-row-rem").show();
  $(".icon-row-rem").first().hide();
  bindAdd();
  bindRem();
  $("#icon-table tr.icon-row:odd td").removeClass('even').addClass("odd");
  $("#icon-table tr.icon-row:even td").removeClass('odd').addClass("even");
}

function bindAdd() {
  $(".icon-row-add").click(function() {
    addNewRow();
    fixButtons();
  });
}

function addNewRow() {
  var oldRow = $(".icon-row:last");
  var newRow = oldRow.clone();
  var index = oldRow.data('index') + 1;
  newRow.data('index', index);

  // clear all input values in the clone
  var inputs = newRow.find('input');
  inputs.val('');

  // clear preview icon
  newRow.find(".preview-icon").attr('src', '').attr('title', '').attr('alt', '');

  // handle the URL field specially
  // because uploads have special UI
  var urlField = inputs.first();
  newRow.find('.conf').hide();
  newRow.find('.conf .filename').text('');
  urlField.show();
  urlField.attr('id', 'icons_'+index+'_url');

  newRow.insertBefore($(".submit-row"));
  $("td:has(input)", newRow).each(function() {
    $(this).keydown(processDirectionalKey);
  });
  return index;
}

function bindRem() {
  $(".icon-row-rem").click(function() {
    var remRow = $(this).parent().parent();
    var removingKey = $(remRow.find('input')[1]).val();
    remRow.remove();
    fixButtons();
    if (removingKey !== '') { deleteUnusedIcons([removingKey]); }
  });
}

function cleanUpRows() {
  $(".icon-row").each(function() {
    var anySet = false;
    if ($(this).find('.conf .filename').text() !== '') return;
    $(this).find('input').each(function() { // eslint-disable-line consistent-return
      if ($(this).val() !== '') {
        anySet = true;
        return false;
      }
    });
    if (!anySet) $(this).remove();
  });
  $(".icon-row").each(function(index) {
    $(this).data('index', index);
    $(this).find('input').first().attr('id', 'icons_'+index+'_url');
  });
  fixButtons();
}

function addUploadedIcon(url, key, data, _fileInput) {
  done += 1;
  updateBox();

  // create hidden field
  var iconIndex = addNewRow();
  var row = $(".icon-row").filter(function() { return $(this).data('index') === iconIndex; });
  var urlInput = $("#icons_"+iconIndex+"_url");
  var urlCell = $(urlInput.parents('td:first'));
  urlInput.hide().val(url);
  row.find("input[id$='_s3_key']").val(key);

  // update keyword box with data.files[0].name minus file extension
  var keyword = data.files[0].name;
  var fileExt = keyword.split('.').slice(-1)[0];
  if (fileExt !== keyword)
    keyword = keyword.replace('.'+fileExt, '');
  row.find("input[id$='_keyword']").val(keyword);

  // Display a preview of the uploaded icon for the user
  row.find(".preview-icon").attr('src', url).attr('title', keyword).attr('alt', keyword);

  // Update and display confirmation box
  row.find("input[id$='_filename']").val(data.files[0].name);
  urlCell.find('.conf .filename').text(data.files[0].name);
  urlCell.find('.conf').show();

  cleanUpRows();
}

function addCallback() {
  total += 1;
  updateBox();
}

function failCallback() {
  failed += 1;
  done += 1;
  updateBox();
}

function updateBox() {
  var progressBox = $(".progress-box");
  if (!progressBox) return;
  var progress = parseInt(done / total * 100, 10);
  progressBox.html(done.toString() + ' / ' + total.toString() + ' (' + progress + '%) ');
  if (failed) {
    progressBox.append($("<span style='color: #F00;'>").append(failed.toString() + " failed"));
  }
}
