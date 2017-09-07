/* global addUploadedIcon, originalUrl, setLoadingIcon, addCallback, failCallback */

var uploadedIcons = {};

$(document).ready(function() {
  var form = $('form.icon-upload');
  var submitButton = form.find('input[type="submit"]');
  var formData = form.data('form-data');

  $(".icon_files").each(function(fileInput) {
    bindFileInput($(fileInput), form, submitButton, formData);
  });

  $("form.icon-upload").submit(function() {
    var usedUrls = $.map($('form.icon-upload').find('input[id$=_url]'), function(input) { return $(input).val(); });
    var uploadedUrls = $.map(uploadedIcons, function(value, key) { return key; });
    var unusedUrls = uploadedUrls.filter(function(x) { return usedUrls.indexOf(x) < 0 });
    if (unusedUrls.length < 1) return true;
    deleteUnusedIcons($.map(unusedUrls, function(url) { return uploadedIcons[url]; }));
  });
});

function bindFileInput(fileInput, form, submitButton, formData) {
  var uploadArgs = {
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
        unsetLoadingIcon();
        return;
      } else if (fileType === 'image/tiff') {
        alert("Unfortunately, .tiff files are only supported by Safari - please retry with a valid file.");
        unsetLoadingIcon();
        return;
      }
      if (typeof addCallback !== 'undefined') addCallback();

      formData["Content-Type"] = fileType;
      data.formData = formData;
      data.submit();
      fileInput.val('');
    },
    start: function() {
      submitButton.prop('disabled', true);
      setLoadingIcon();
    },
    done: function(e, data) {
      submitButton.prop('disabled', false);

      // extract key and generate URL from response
      var s3Key = $(data.jqXHR.responseXML).find("Key").text();
      var url = $(data.jqXHR.responseXML).find("Location").text();
      uploadedIcons[url] = s3Key;

      // Handled differently by different pages; handles UI and form updates
      addUploadedIcon(url, s3Key, data, fileInput);
    },
    fail: function(e, data) {
      submitButton.prop('disabled', false);
      if (typeof failCallback !== 'undefined') failCallback();
      unsetLoadingIcon();
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
      if (response.readyState === 0) {
        alert("Upload of " + data.files[0].name + " failed due to a network error. Please check your connection and try again.");
      } else if (policyExpired) {
        alert("Your upload permissions appear to have expired. Please refresh the page and try again.");
      } else if (badFiletype) {
        alert("You must upload files with an image filetype such as .png or .jpg - please retry with a valid file.");
      } else {
        $.post('/bugs', bugsData);
        alert("Upload of " + data.files[0].name + " failed, Marri has been notified.");
      }
    },
  };

  // If specified, limit number of files
  if (typeof form.data('limit') !== 'undefined')
    uploadArgs.maxNumberOfFiles = form.data('limit');

  fileInput.fileupload(uploadArgs);
}

function unsetLoadingIcon() {
  if ($("#edit-icon").length)
    $("#edit-icon").attr('src', originalUrl).css('height', '');
}

function deleteUnusedIcons(keys) {
  $(keys).each(function(key) {
    $.post('/api/v1/icons/s3_delete', {s3_key: key});
  });
}
