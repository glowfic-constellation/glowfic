$(document).ready(function() {
  $("#tag-view").select2({
    width: '200px',
    minimumResultsForSearch: 10,
    placeholder: '— Choose Type —',
    allowClear: true,
    dropdownParent: $('.index-search'),
  });
});
