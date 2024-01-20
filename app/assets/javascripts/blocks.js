/* global createSelect2, processResults, queryTransform */
$(document).ready(function() {
  createSelect2("#block_blocked_user_id", {
    ajax: {
      url: '/api/v1/users',
      data: function(params) {
        const data = queryTransform(params);
        data.hide_unblockable = true;
        return data;
      },
      processResults: function(data, params) {
        const total = this._request.getResponseHeader('Total');
        return processResults(data, params, total, 'username');
      },
    },
    placeholder: '— Choose User —',
    allowClear: true,
  });
});
