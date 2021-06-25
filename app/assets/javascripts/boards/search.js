/* global createSelect2, processResults */

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

function processTotal(key) {
  return function(data, params) {
    var total = this._request.getResponseHeader('Total');
    return processResults(data, params, total, key);
  };
}
