/* global createSelect2 */

$(document).ready(function() {
  createSelect2("#continuity_coauthor_ids", {
    minimumResultsForSearch: 10,
    placeholder: 'Open to Anyone'
  });
  createSelect2("#continuity_cameo_ids", {
    minimumResultsForSearch: 10,
    placeholder: '(Optional)'
  });
});
