$(document).ready(function() {
  $(".per-page").select2({width: '70px'});
  $(".per-page").change(function () {
    location.href = add_parameter(location.href, 'per_page', $(this).val());
  });
});
