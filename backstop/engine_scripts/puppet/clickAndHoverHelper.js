module.exports = async (page, givenScenario) => {
  const defaults = {
    hoverSelectors: [],
    clickSelectors: [],
    keyPressSelectors: [],
    // clickNavigates: the clicks submit a form or follow a link; wait for the new page to load
    clickNavigates: false,
    // postInteractionWait: ms [int]
    postInteractionWait: null,
    scrollToSelector: null,
  };
  const config = Object.assign(defaults, givenScenario);

  for (const keyPressSelectorItem of config.keyPressSelectors) {
    await page.waitForSelector(keyPressSelectorItem.selector);
    await page.type(keyPressSelectorItem.selector, keyPressSelectorItem.keyPress);
  }

  for (const hoverSelectorItem of config.hoverSelectors) {
    await page.waitForSelector(hoverSelectorItem);
    await page.hover(hoverSelectorItem);
  }

  for (const clickSelectorItem of config.clickSelectors) {
    await page.waitForSelector(clickSelectorItem);
    if (config.clickNavigates) {
      await Promise.all([page.waitForNavigation({ waitUntil: 'networkidle0' }), page.click(clickSelectorItem)]);
    } else {
      await page.click(clickSelectorItem);
    }
  }

  if (config.postInteractionWait) {
    await new Promise((resolve) => setTimeout(resolve, config.postInteractionWait)); // page.waitForTimeout was removed in Puppeteer 22 (BackstopJS 6)
  }

  if (config.scrollToSelector) {
    await page.waitForSelector(config.scrollToSelector);
    await page.evaluate(scrollToSelector => {
      document.querySelector(scrollToSelector).scrollIntoView();
    }, config.scrollToSelector);
  }
};
