/* global createSelect2 */
$(document).ready(function() {
  createSelect2('#access_circle_user_ids', {
    width: '200px',
    minimumResultsForSearch: 20,
    placeholder: 'Choose users(s) for this circle'
  });
});
