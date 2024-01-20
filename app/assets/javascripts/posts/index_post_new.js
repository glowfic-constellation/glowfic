/* global createSelect2, processResults, queryTransform */
$(document).ready(function() {
  createSelect2('#index_post_post_id', {
    ajax: {
      url: '/api/v1/posts',
      data: function(params) { return queryTransform(params); },
      processResults: function(data, params) {
        const total = this._request.getResponseHeader('Total');
        return processResults(data, params, total, 'subject');
      },
    },
    placeholder: '— Choose Post —',
    allowClear: true,
  });
});
