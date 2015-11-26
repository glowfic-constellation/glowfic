$(document).ready(function() {
  $(".per-page").chosen({
    width: '70px',
    disable_search_threshold: 20,
  });

  $(".per-page").change(function () {
    location.href = add_parameter(location.href, 'per_page', $(this).val());
  });
});