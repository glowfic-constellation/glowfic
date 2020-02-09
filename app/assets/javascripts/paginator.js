/* global createSelect2, addParameter */
$(document).ready(function() {
  createSelect2('.per-page', {width: '70px'});
  $(".per-page").change(function() {
    location.href = addParameter(location.href, 'per_page', $(this).val());
  });
});
