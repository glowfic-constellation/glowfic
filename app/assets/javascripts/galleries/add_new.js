/* global deleteUnusedIcons */
/* exported addUploadedIcon, addCallback, failCallback */

let done = 0;
let total = 0;
let failed = 0;

const keyLeft = 37;
const keyUp = 38;
const keyRight = 39;
const keyDown = 40;

const emptyGif = "data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==";

$(document).ready(function() {
  fixButtons();
  $(".icon-row td:has(input)").each(function() {
    $(this).keydown(processDirectionalKey);
  });
});

// eslint-disable-next-line complexity
function processDirectionalKey(event) {
  if ([keyLeft, keyUp, keyRight, keyDown].indexOf(event.which) < 0) return; // skip if not a directional key
  const tdBinding = $(this);
  const input = $('input', tdBinding);
  if (input.get(0).type !== 'text') { return; } // skip if not text
  if (input.get(0).selectionStart !== input.get(0).selectionEnd) { return; } // skip processing if user has text selected

  const caret = input.get(0).selectionStart;
  const index = tdBinding.closest('td').index();

  let consume = false;
  switch (event.which) {
  case keyLeft:
    consume = processKeyLeft(tdBinding, caret);
    break;
  case keyRight:
    consume = processKeyRight(tdBinding, caret, input.val().length);
    break;
  case keyUp:
    tdBinding.closest('tr').prev('.icon-row').children().eq(index).find('input').focus();
    consume = true;
    break;
  case keyDown:
    tdBinding.closest('tr').next('.icon-row').children().eq(index).find('input').focus();
    consume = true;
    break;
  }
  if (consume) event.preventDefault();
}

function processKeyLeft(binding, caret) {
  if (caret !== 0) { return false; }
  binding.closest('td').prev().find('input').focus();
  return true;
}

function processKeyRight(binding, caret, length) {
  if (caret < length) { return false; }
  binding.closest('td').next().find('input').focus();
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
  const oldRow = $(".icon-row:last");
  const newRow = oldRow.clone();
  const index = oldRow.data('index') + 1;
  newRow.data('index', index);

  // clear all input values in the clone
  const inputs = newRow.find('input');
  inputs.val('');

  // clear preview icon
  newRow.find(".preview-icon").attr('src', emptyGif).attr('title', '').attr('alt', '');

  // handle the URL field specially
  // because uploads have special UI
  const urlField = inputs.first();
  newRow.find('.conf').hide();
  newRow.find('.conf .filename').text('');
  urlField.show();
  inputs.each(function() {
    $(this).attr('id', $(this).attr('id').replace(/_\d+_/g, '_'+index+'_'));
  });

  newRow.insertAfter(oldRow);
  $("td:has(input)", newRow).each(function() {
    $(this).keydown(processDirectionalKey);
  });
  return index;
}

function bindRem() {
  $(".icon-row-rem").click(function() {
    const remRow = $(this).parents('tr');
    const removingKey = $(remRow.find('input')[1]).val();
    remRow.remove();
    fixButtons();
    if (removingKey !== '') { deleteUnusedIcons([removingKey]); }
  });
}

function cleanUpRows() {
  $(".icon-row").each(function() {
    let anySet = false;
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
  const iconIndex = addNewRow();
  const row = $(".icon-row").filter(function() { return $(this).data('index') === iconIndex; });
  const urlInput = $("#icons_"+iconIndex+"_url");
  const urlCell = $(urlInput.parents('td:first'));
  urlInput.hide().val(url);
  row.find("input[id$='_s3_key']").val(key);

  // update keyword box with data.files[0].name minus file extension
  let keyword = data.files[0].name;
  const fileExt = keyword.split('.').slice(-1)[0];
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
  const progressBox = $(".progress-box");
  if (!progressBox) return;
  const progress = parseInt(done / total * 100, 10);
  progressBox.html(done.toString() + ' / ' + total.toString() + ' (' + progress + '%) ');
  if (failed) {
    progressBox.append($("<span style='color: #F00;'>").append(failed.toString() + " failed"));
  }
}
