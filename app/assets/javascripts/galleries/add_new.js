$(document).ready(function() {
  fixButtons();
  $(".icon-row td:has(input)").each(function() {
    $(this).keydown(processDirectionalKey);
  });
  bindFileInput($("#icon_files"));
});

function processDirectionalKey(event) {
  var keyLeft = 37,
    keyUp = 38,
    keyRight = 39,
    keyDown = 40;
  if ([keyLeft, keyUp, keyRight, keyDown].indexOf(event.which) < 0) return;
  var input = $('input', this);
  if (input.get(0).type !== 'text') return;

  var caret = input.get(0).selectionStart;
  var length = input.val().length;
  var index = $(this).closest('td').index();

  var consume = false;
  switch (event.which) {
  case keyLeft:
    if (caret === 0) {
      $(this).closest('td').prev().find('input').focus();
      consume = true;
    }
    break;
  case keyRight:
    if (caret >= length) {
      $(this).closest('td').next().find('input').focus();
      consume = true;
    }
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

  // handle the URL field specially
  // because uploads have special UI
  var urlField = inputs.first();
  newRow.find('.conf').remove();
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
    remRow.remove();
    fixButtons();
  });
}

function bindFileInput(fileInput) {
  var form = $('form.icon-upload');
  var submitButton = form.find('input[type="submit"]');
  var formData = form.data('form-data');

  fileInput.fileupload({
    fileInput: fileInput,
    url: form.data('url'),
    type: 'POST',
    autoUpload: true,
    formData: formData,
    paramName: 'file', // S3 does not like nested name fields i.e. name="user[avatar_url]"
    dataType: 'XML', // S3 returns XML if success_action_status is set to 201
    replaceFileInput: false,

    add: function(e, data) {
      var fileType = data.files[0].type;
      if (!fileType.startsWith('image/')) {
        alert("You must upload files with an image filetype such as .png or .jpg - please retry with a valid file.");
        return;
      } else if (fileType === 'image/tiff') {
        alert("Unfortunately, .tiff files are only supported by Safari - please retry with a valid file.");
        return;
      }

      formData["Content-Type"] = fileType;
      data.formData = formData;
      data.submit();
      fileInput.val('');
    },
    start: function() {
      submitButton.prop('disabled', true);
    },
    done: function(e, data) {
      submitButton.prop('disabled', false);

      // extract key and generate URL from response
      var key = $(data.jqXHR.responseXML).find("Key").text();
      var url = 'https://d1anwqy6ci9o1i.cloudfront.net/' + key;

      // create hidden field
      var iconIndex = addNewRow();
      var row = $(".icon-row").filter(function() { return $(this).data('index') === iconIndex; });
      var urlInput = $("#icons_"+iconIndex+"_url");
      var urlCell = $(urlInput.parents('td:first'));
      urlInput.hide().val(url);
      urlCell.find('.conf').remove();

      // update keyword box with data.files[0].name minus file extension
      var keyword = data.files[0].name;
      var fileExt = keyword.split('.').slice(-1)[0];
      if (fileExt !== keyword)
        keyword = keyword.replace('.'+fileExt, '');
      row.find("input[id$='_keyword']").val(keyword);

      var uploaded = ' Uploaded ' + data.files[0].name;
      urlCell.append("<span class='conf'><img src='/images/accept.png' alt='' title='Successfully uploaded' class='vmid' />"+uploaded+"</span>");
      cleanUpRows();
    },
    fail: function(e, data) {
      submitButton.prop('disabled', false);
      var response = data.response().jqXHR;
      var policyExpired = response.responseText.includes("Invalid according to Policy: Policy expired.");
      if (!policyExpired) policyExpired = response.responseText.includes("Idle connections will be closed.");
      var badFiletype = response.responseText.includes("Policy Condition failed") && response.responseText.includes('"$Content-Type", "image/"');
      var bugsData = {
        'response_status': response.status,
        'response_body': response.responseText,
        'response_text': response.statusText,
        'file_name': data.files[0].name,
        'file_type': data.files[0].type,
      };
      if (policyExpired) {
        alert("Your upload permissions appear to have expired. Please refresh the page and try again.");
      } else if (badFiletype) {
        alert("You must upload files with an image filetype such as .png or .jpg - please retry with a valid file.");
      } else {
        $.post('/bugs', bugsData);
        alert("Upload of " + data.files[0].name + " failed, Marri has been notified.");
      }
    },
  });
}

function cleanUpRows() {
  $(".icon-row").each(function() {
    var anySet = false;
    if ($(this).find('.conf').length > 0) return;
    $(this).find('input').each(function() {
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
