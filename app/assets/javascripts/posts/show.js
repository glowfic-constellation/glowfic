/* global resizeScreenname */
$(document).ready(function() {
  // Checks if the user is on the unread page but also started near the unread element,
  // since e.g. on a refresh some browsers will retain your spot on the page
  // Will be used after some page-size-changing functions to revert to the correct spot
  const unreadElem = $("a#unread");
  let shouldScrollToUnread = false;
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
      const charCode = e.which || e.keyCode;
      if (charCode === 27) {
        $('#post-menu-box').hide();
        $('#post-menu').removeClass('selected');
      }
    });

    // Hides selectors when you click outside them
    $(document).click(function(e) {
      const target = e.target;

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
    const paginators = $('.paginator');
    paginators.each(function() { reflowPaginator(this); });
    let resizeDebounce = null;
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
  const pagination = paginator.find('.normal-pagination');
  const narrowClear = paginator.find('.narrow-clear');

  narrowClear.css('clear', 'none');
  paginator.removeClass('mobile-paginator');

  let innerWindow = 4;
  const outerBoundary = 2;
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
  const list = [];
  for (let i=lower; i<=upper; i++) {
    list.push(i);
  }
  return list;
}

function calculateVisiblePages(innerWindow, outerBoundary, totalPages, currentNum) {
  let windowFrom = currentNum - innerWindow;
  let windowTo = currentNum + innerWindow;
  if (windowTo > totalPages) {
    windowFrom -= windowTo - totalPages;
    windowTo = totalPages;
  }
  if (windowFrom < 1) {
    windowTo += 1 - windowFrom;
    windowFrom = 1;
    if (windowTo > totalPages) windowTo = totalPages;
  }

  const middle = range(windowFrom, windowTo);

  let left;
  if (outerBoundary + 3 < middle[0]) {
    left = range(1, outerBoundary+1);
    left.push('gap');
  } else {
    left = range(1, middle[0]);
  }

  let right;
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
  const links = paginator.find('a:not(.previous_page):not(.next_page)');
  links.show();

  // logic for page numbers from will_paginate
  const lastLink = paginator.find('.next_page').prev('a,.current');
  const current = paginator.find('.current');
  const currentNum = pageAsNumber(current);
  const totalPages = pageAsNumber(lastLink);
  const pages = calculateVisiblePages(innerWindow, outerBoundary, totalPages, currentNum);

  let linksToHide = links;
  links.each(function() {
    const link = $(this);
    const num = pageAsNumber(link);
    const index = pages.indexOf(num);
    if (index < 0) return;
    linksToHide = linksToHide.not(link);
    if (pages[index + 1] === 'gap' && !link.next('.gap')) link.after(newInsertedEllipsis());
  });

  linksToHide.hide();
}
