/* global addUploadedIcon */
$(document).ready(function() {
  bindFileInput($("#icon_files"));
});

function updateBox(progressBox, done, total, failed) {
  if (!progressBox) return;
  var progress = parseInt(done / total * 100, 10);
  progressBox.html(done.toString() + ' / ' + total.toString() + ' (' + progress + '%) ');
  if (failed) {
    progressBox.append($("<span style='color: #f00;'>").append(failed.toString() + " failed"));
  }
}

function bindFileInput(fileInput) {
  var form = $('form.icon-upload');
  var submitButton = form.find('input[type="submit"]');
  var formData = form.data('form-data');
  var progressBox = fileInput.closest('td').find('.progressBox');
  var done = 0;
  var total = 0;
  var failed = 0;

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
        return;
      } else if (fileType === 'image/tiff') {
        alert("Unfortunately, .tiff files are only supported by Safari - please retry with a valid file.");
        return;
      }
      total += 1;
      updateBox(progressBox, done, total, failed);

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
      done += 1;
      updateBox(progressBox, done, total, failed);

      // extract key and generate URL from response
      var key = $(data.jqXHR.responseXML).find("Key").text();
      var url = 'https://d1anwqy6ci9o1i.cloudfront.net/' + key;

      addUploadedIcon(url, data);
    },
    fail: function(e, data) {
      submitButton.prop('disabled', false);
      failed += 1;
      updateBox(progressBox, done, total, failed);
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
