var originalUrl;
$(document).ready(function() {
  originalUrl = $("#edit-icon").attr('src');
});

function addUploadedIcon(url, s3_key, data, fileInput) {
  $("#icon_conf").show();
  $("#icon_url_field").hide();
  $("#icon_url").hide().val(url);
  $("#icon_s3_key").val(s3_key);
  $("#edit-icon").attr('src', url).css('height', '');
}

function setLoadingIcon() {
  $("#edit-icon").attr('src', '/images/loading.gif').css('height', '20px');
}
