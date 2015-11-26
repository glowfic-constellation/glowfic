$(document).ready(function () {
  $(".gallery-box").click(function() {
    var id = $(this).attr('id');
    $('#gallery'+id).toggle();
    $(this).html($(this).html() == '-' ? '+' : '-');
  });

  $(".gallery-delete").click(function() {
    var icon_id = $(this).attr('id');
    var gallery_id = $(this).attr('gallery');
    var url = '/galleries/'+gallery_id+'/remove';
    $.ajax({url: url, type: 'DELETE', data: { icon_id: icon_id }, success: function() {
        $('#gallery'+gallery_id+' #icon'+icon_id).remove();
        if($("#gallery"+gallery_id).children().size() == 0) {
            $("#gallery"+gallery_id).append('<div class="centered">— No icons yet —</div>');
        }
    }});
  });
});
