image_ids = []
$(document).ready( function() {
  fixButtons();

  $(".add-gallery-icon").click(function() {
    $(this).toggleClass('selected-icon');
    if ($(this).hasClass('selected-icon')) {
      image_ids.push(this.dataset['id']);
    } else {
      image_ids.pop(this.dataset['id']);
    }
  });

  $("#add-gallery-icons").submit(function() {
    if (image_ids.length < 1) { return false; }
    $("#image_ids").val(image_ids);
    return true;
  });
});

function bindAdd() { 
  $(".icon-row-add").click(function () {
    var new_row = $(".icon-row:last").clone();
    var index = new_row.data('index') + 1;
    var inputs = new_row.find('input');
    var urlField = inputs.first();
    var fileField = $(inputs.get(1));

    new_row.attr('data-index', index);
    inputs.val('');

    new_row.find('.conf').remove();
    urlField.show();
    urlField.attr('id', 'icons_'+index+'_url');

    fileField.attr('id', 'icons_'+index+'_file');
    fileField.attr('data-index', index);
    bindFileInput(inputs.get(1));

    new_row.insertBefore($(".submit-row"));
    fixButtons();
  });
};

function bindRem() {
  $(".icon-row-rem").click(function () {
    var rem_row = $(this).parent().parent();
    rem_row.remove();
    fixButtons();
  });
};

function fixButtons() {
  $(".icon-row-add").hide().unbind();
  $(".icon-row-add").last().show();
  $(".icon-row-rem").show();
  $(".icon-row-rem").first().hide();
  bindAdd();
  bindRem();
  $("#icon-table tr.icon-row:odd td").removeClass('even').addClass("odd");
  $("#icon-table tr.icon-row:even td").removeClass('odd').addClass("even");
};

$(function() {
  $('.icon-upload').find("input:file").each(function(i, elem) {
    bindFileInput(elem);
  });
});

function bindFileInput(elem) {
    var fileInput    = $(elem);
    var form         = $('form.icon-upload');
    var submitButton = form.find('input[type="submit"]');
    var iconIndex    = $(elem).data('index');
    var formData     = form.data('form-data');

    fileInput.fileupload({
      fileInput:       fileInput,
      url:             form.data('url'),
      type:            'POST',
      autoUpload:       true,
      formData:         formData,
      paramName:        'file', // S3 does not like nested name fields i.e. name="user[avatar_url]"
      dataType:         'XML',  // S3 returns XML if success_action_status is set to 201
      replaceFileInput: false,
      add: function (e, data) {
        formData["Content-Type"] = data.files[0].type; 
        data.formData = formData;
        data.submit();
      },
      start: function (e) {
        submitButton.prop('disabled', true);
      },
      done: function(e, data) {
        submitButton.prop('disabled', false);

        // extract key and generate URL from response
        var key   = $(data.jqXHR.responseXML).find("Key").text();
        var url   = 'https://d1anwqy6ci9o1i.cloudfront.net/' + key;

        // create hidden field
        var urlInput = $("#icons_"+iconIndex+"_url");
        var urlCell = $(urlInput.parents('td:first'));
        urlInput.hide().val(url);
        var uploaded = ' Uploaded ' + fileInput.val().split("\\").pop();
        urlCell.append("<span class='conf'><img src='/images/accept.png' alt='' title='Successfully uploaded' class='vmid' />"+uploaded+"</span>");
      },
      fail: function(e, data) {
        submitButton.prop('disabled', false);
        var response = data.response().jqXHR
        var policyExpired = response.responseText.includes("Invalid according to Policy: Policy expired.");
        $.post('/bugs', {'response_status':response.status, 'response_body': response.responseText, 'response_text': response.statusText, expired: policyExpired});
        if (policyExpired) {
          alert("Your upload permissions appear to have expired. Please refresh the page and try again.");
        } else {
          alert("Upload failed, Marri has been notified.");
        }
      },
    });
};
