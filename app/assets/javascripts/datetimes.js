/* global gon */
window.onload = function() {
  if (gon.logged_in) return;
  const format = Intl.DateTimeFormat('en-US', {
    dateStyle: 'medium',
    timeStyle: 'short',
  });

  const times = document.getElementsByTagName('time');
  Array.from(times).forEach(function(time) {
    const datetime = new Date(time.dateTime);
    time.innerText = format.format(datetime);
  });
};
