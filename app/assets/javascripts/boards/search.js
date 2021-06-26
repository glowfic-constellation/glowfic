/* global createSelect2, processTotal */

$(document).ready(function() {
  createSelect2('#author_id', {
    ajax: {
      url: '/api/v1/users',
      processResults: processTotal('username'),
    },
    placeholder: '— Choose Author —',
    allowClear: true,
  });
});
