$(document).ready(function() {
    fixButtons();
});

function bindAdd() { 
  $(".icon-row-add").click(function () {
    var new_row = $("#icon-table tbody>tr.icon-row:first").clone();
    new_row.find('input').val('');
    new_row.insertBefore($(".submit-row"));
    fixButtons();
  });
};

function bindRem() {
  $(".icon-row-rem").click(function () {
    var rem_row = $(this).parent().parent();
    rem_row.remove();
    fixButtons();
  });
}

function fixButtons() {
  $(".icon-row-add").hide().unbind();
  $(".icon-row-add").last().show();
  $(".icon-row-rem").show();
  $(".icon-row-rem").first().hide();
  bindAdd();
  bindRem();
}
