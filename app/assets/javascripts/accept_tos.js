$(document).ready(function() {
  // Use hide/show for anonymous users rather than removing content
  // server-side improves SEO as search bots can still scrape content.
  $("#content").hide();
  $("#tos").show();
});
