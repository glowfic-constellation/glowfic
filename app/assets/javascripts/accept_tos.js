$(document).ready(function() {
  // Use hide/show for anonymous users rather than removing content
  // server-side improves SEO as search bots can still scrape content.
  if ($("#tos").length > 0) {
    $("#content").hide();
    $("#tos").show();
  }
});
