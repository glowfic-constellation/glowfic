$(document).ready(function() {
  $(".per-page").select2({
    width: '70px',
    minimumResultsForSearch: 20,
  });

  $(".per-page").change(function () {
    location.href = add_parameter(location.href, 'per_page', $(this).val());
  });
});