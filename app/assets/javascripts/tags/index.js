/* global createSelect2 */

$(document).ready(function() {
  createSelect2('#tag-view', {
    width: '200px',
    minimumResultsForSearch: 10,
    placeholder: '— Choose Type —',
    allowClear: true,
  });
});
