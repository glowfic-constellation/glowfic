module.exports = async (page, givenScenario) => {
  const defaults = {
    hoverSelectors: [],
    clickSelectors: [],
    keyPressSelectors: [],
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
    await page.click(clickSelectorItem);
  }

  if (config.postInteractionWait) {
    await page.waitForTimeout(config.postInteractionWait);
  }

  if (config.scrollToSelector) {
    await page.waitForSelector(config.scrollToSelector);
    await page.evaluate(scrollToSelector => {
      document.querySelector(scrollToSelector).scrollIntoView();
    }, config.scrollToSelector);
  }
};
