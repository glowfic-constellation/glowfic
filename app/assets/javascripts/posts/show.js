/* global resizeScreenname */
$(document).ready(function() {
  // Checks if the user is on the unread page but also started near the unread element,
  // since e.g. on a refresh some browsers will retain your spot on the page
  // Will be used after some page-size-changing functions to revert to the correct spot
  var unreadElem = $("a#unread");
  var shouldScrollToUnread = false;
  if (window.location.hash === "#unread" && unreadElem.length > 0)
    shouldScrollToUnread = Math.abs(unreadElem.offset().top - $(window).scrollTop()) < 50;

  $(".post-expander:not(.post-editor-expander)").click(function() {
    $(this).children(".info").remove();
    $(this).get(0).outerHTML = $(this).children('.hidden').html();
  });

  // Dropdown menu code
  if ($("#post-menu").length > 0) {
    $("#post-menu").click(function() {
      $(this).toggleClass('selected');
      $("#post-menu-box").toggle();
    });

    // Hides selectors when you hit the escape key
    $(document).bind("keydown", function(e) {
      e = e || window.event;
      var charCode = e.which || e.keyCode;
      if (charCode === 27) {
        $('#post-menu-box').hide();
        $('#post-menu').removeClass('selected');
      }
    });

    // Hides selectors when you click outside them
    $(document).click(function(e) {
      var target = e.target;

      if (!$(target).is('#post-menu-box') && !$(target).parents().is('#post-menu-box')
        && !$(target).is('#post-menu') && !$(target).parents().is('#post-menu')) {
        $('#post-menu-box').hide();
        $('#post-menu').removeClass('selected');
      }
    });
  }

  // TODO fix hack
  // Resizes screennames to be slightly smaller if they're long for UI reasons
  $(".post-screenname").each(function() {
    resizeScreenname(this);
  });

  // horrible hack to make the paginator center-aligned when it's forced to a second line
  // the timeout in the resize event acts as a debounce so we don't re-render on each pixel change of the resize
  if ($(".normal-pagination").length > 0) {
    var paginators = $('.paginator');
    paginators.each(function() { reflowPaginator(this); });
    var resizeDebounce = null;
    $(window).resize(function() {
      window.cancelAnimationFrame(resizeDebounce);
      resizeDebounce = window.requestAnimationFrame(function() {
        paginators.each(function() { reflowPaginator(this); });
      });
    });
  }

  // Now that we've finished the scripts that change page locations, scroll to #unread
  // if we determined on page load that we should.
  if (shouldScrollToUnread)
    $(window).scrollTop(unreadElem.offset().top);
});

function reflowPaginator(paginator) {
  paginator = $(paginator);
  var pagination = paginator.find('.normal-pagination');
  var narrowClear = paginator.find('.narrow-clear');

  narrowClear.css('clear', 'none');
  paginator.removeClass('mobile-paginator');

  var innerWindow = 4;
  var outerBoundary = 2;
  hidePaginatorLinks(pagination, innerWindow, outerBoundary);
  if (paginator.height() < 60) return;

  narrowClear.css('clear', 'both');

  if (paginator.height() < 100) return;
  while (paginator.height() >= 100 && innerWindow > 0) {
    hidePaginatorLinks(pagination, innerWindow, outerBoundary);
    innerWindow -= 1;
  }

  if (paginator.height() < 100) return;
  paginator.addClass('mobile-paginator');
}

function pageAsNumber(page) {
  return parseInt(page.html().trim(), 10);
}

function newInsertedEllipsis() {
  return $('<span class="gap inserted-ellipsis">').append('…');
}

function range(lower, upper) {
  // [lower .. upper] (inclusive)
  var list = [];
  for (var i=lower; i<=upper; i++) {
    list.push(i);
  }
  return list;
}

function calculateVisiblePages(innerWindow, outerBoundary, totalPages, currentNum) {
  var windowFrom = currentNum - innerWindow;
  var windowTo = currentNum + innerWindow;
  if (windowTo > totalPages) {
    windowFrom -= windowTo - totalPages;
    windowTo = totalPages;
  }
  if (windowFrom < 1) {
    windowTo += 1 - windowFrom;
    windowFrom = 1;
    if (windowTo > totalPages) windowTo = totalPages;
  }

  var middle = range(windowFrom, windowTo);

  var left;
  if (outerBoundary + 3 < middle[0]) {
    left = range(1, outerBoundary+1);
    left.push('gap');
  } else {
    left = range(1, middle[0]);
  }

  var right;
  if (totalPages - outerBoundary - 2 > middle[middle.length-1]) {
    right = range(totalPages - outerBoundary, totalPages);
  } else {
    right = range(middle[middle.length-1] + 1, totalPages);
    right.unshift('gap');
  }

  return left.concat(middle).concat(right);
}

function hidePaginatorLinks(paginator, innerWindow, outerBoundary) {
  paginator.find('.inserted-ellipsis').remove();
  var links = paginator.find('a:not(.previous_page):not(.next_page)');
  links.show();

  // logic for page numbers from will_paginate
  var lastLink = paginator.find('.next_page').prev('a,.current');
  var current = paginator.find('.current');
  var currentNum = pageAsNumber(current);
  var totalPages = pageAsNumber(lastLink);
  var pages = calculateVisiblePages(innerWindow, outerBoundary, totalPages, currentNum);

  var linksToHide = links;
  links.each(function() {
    var link = $(this);
    var num = pageAsNumber(link);
    var index = pages.indexOf(num);
    if (index < 0) return;
    linksToHide = linksToHide.not(link);
    if (pages[index + 1] === 'gap' && !link.next('.gap')) link.after(newInsertedEllipsis());
  });

  linksToHide.hide();
}
