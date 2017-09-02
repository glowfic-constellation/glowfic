/* global gon */
function queryTransform(params) {
  var data = {
    q: params.term,
    page: params.page
  };
  return data;
}

function processResults(data, params, total, textKey) {
  params.page = params.page || 1;
  var processed = {
    results: data.results,
    pagination: {more: (params.page * 25) < total}
  };
  if (textKey) {
    // Reformat response data
    var formatted = [];
    for (var i=0; i < data.results.length; i++) {
      var result = data.results[i];
      formatted[i] = {
        id: result.id,
        text: result[textKey]
      };
    }
    processed.results = formatted;
  }
  return processed;
}

$(document).ready(function() {
  $("#setting_id").select2({
    ajax: {
      delay: 200,
      url: '/api/v1/tags',
      dataType: 'json',
      data: function(params) {
        var data = queryTransform(params);
        data.t = 'Setting';
        return data;
      },
      processResults: function(data, params) {
        var total = this._request.getResponseHeader('Total');
        return processResults(data, params, total);
      },
      cache: true
    },
    placeholder: '— Choose Setting —',
    allowClear: true,
    width: '100%'
  });

  $("#character_id").select2({
    ajax: {
      delay: 200,
      url: '/api/v1/characters',
      dataType: 'json',
      data: function(params) {
        var data = queryTransform(params);
        if (typeof gon !== 'undefined') data.post_id = gon.post_id;
        return data;
      },
      processResults: function(data, params) {
        var total = this._request.getResponseHeader('Total');
        return processResults(data, params, total, 'name');
      },
      cache: true
    },
    placeholder: '— Choose Character —',
    allowClear: true,
    width: '100%'
  });

  $("#author_id").select2({
    ajax: {
      delay: 200,
      url: '/api/v1/users',
      dataType: 'json',
      data: queryTransform,
      processResults: function(data, params) {
        var total = this._request.getResponseHeader('Total');
        return processResults(data, params, total, 'username');
      },
      cache: true
    },
    placeholder: '— Choose Author —',
    allowClear: true,
    width: '100%'
  });

  $("#board_id").select2({
    ajax: {
      delay: 200,
      url: '/api/v1/boards',
      dataType: 'json',
      data: queryTransform,
      processResults: function(data, params) {
        var total = this._request.getResponseHeader('Total');
        return processResults(data, params, total, 'name');
      },
      cache: true
    },
    placeholder: '— Choose Continuity —',
    allowClear: true,
    width: '100%'
  });

  $("#template_id").select2({
    ajax: {
      delay: 200,
      url: '/api/v1/templates',
      dataType: 'json',
      data: function(params) {
        var data = queryTransform(params);
        var authorId = $("#author_id").val();
        if( authorId !== '' && authorId !== undefined) { data.user_id = authorId; }
        return data;
      },
      processResults: function(data, params) {
        var total = this._request.getResponseHeader('Total');
        return processResults(data, params, total, 'name');
      },
      cache: true
    },
    placeholder: '— Choose Template —',
    allowClear: true,
    width: '100%'
  });
});
