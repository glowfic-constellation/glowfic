/* global createSelect2, processTotal */

$(document).ready(function() {
  createSelect2('#view', {
    width: '200px',
    minimumResultsForSearch: 10,
    placeholder: '— Choose Type —',
    allowClear: true,
  });

  createSelect2('#author_id', {
    ajax: {
      url: '/api/v1/users',
      processResults: processTotal('username'),
    },
    placeholder: '— Choose Author —',
    allowClear: true,
  });
});
