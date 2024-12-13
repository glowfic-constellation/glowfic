$(document).ready(function() {
  $('.checkbox-set').each(function() {
    // For multiple sets of checkboxes on the same page
    const $set = $(this);
    const $checkAll = $set.find('.check-all');
    const $childCheckboxes = $set.find('.checkbox');

    // When the "Check All" checkbox is toggled
    $checkAll.on('change', function() {
      $childCheckboxes.prop('checked', this.checked);
    });

    // When any child checkbox is toggled
    $childCheckboxes.on('change', function() {
      const allChecked = $childCheckboxes.length === $childCheckboxes.filter(':checked').length;
      $checkAll.prop('checked', allChecked);
    });
  });
});
