/* global createTagSelect, createSelect2 */

$(document).ready(function() {
  createSelect2('#user_per_page', {
    width: '70px',
    minimumResultsForSearch: 20,
  });

  createSelect2('#user_default_view', {
    width: '100px',
    minimumResultsForSearch: 20,
  });

  createSelect2('#user_default_character_split', {
    width: '250px',
    minimumResultsForSearch: 20,
  });

  createSelect2('#user_default_editor', {
    width: '100px',
    minimumResultsForSearch: 20,
  });

  createTagSelect("ContentWarning", "content_warning", "user");

  createSelect2('#user_layout', {
    width: '150px',
    minimumResultsForSearch: 20,
  });

  createSelect2('#user_timezone', {width: '250px'});

  createSelect2('#user_time_display', {
    width: '200px',
    minimumResultsForSearch: 20
  });
});
