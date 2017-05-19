$(document).ready(function() {
  $("#setting_id").select2({
    ajax: {
      delay: 200,
      url: '/api/v1/tags',
      dataType: 'json',
      data: function(params) {
        var data = {
          q: params.term,
          t: 'Setting',
          page: params.page
        };
        return data
      },
      processResults: function (data, params) {
        params.page = params.page || 1;
        var total = this._request.getResponseHeader('Total');
        return {
          results: data.results,
          pagination: {
            more: (params.page * 25) < total
          }
        }
      },
      cache: true
    },
    width: '100%'
  });

  $("#character_id").select2({
    ajax: {
      delay: 200,
      url: '/api/v1/characters',
      dataType: 'json',
      data: function(params) {
        var data = {
          q: params.term,
          page: params.page
        };
        if(typeof(gon) !== 'undefined') { data.post_id = gon.post_id }
        return data
      },
      processResults: function (data, params) {
        params.page = params.page || 1;
        var total = this._request.getResponseHeader('Total');

        // Reformat the response to be 
        var formattedChars = []
        for(var i = 0; i < data.results.length; i++) {
          formattedChars[i] = {
            id: data.results[i].id,
            text: data.results[i].name
          }
        }
        return {
          results: formattedChars,
          pagination: {
            more: (params.page * 25) < total
          }
        }
      },
      cache: true
    },
    width: '100%'
  });
});
