module.exports = async (page, givenScenario) => {
  const defaults = {
    hoverSelectors: [],
    clickSelectors: [],
    keyPressSelectors: [],
    // postInteractionWait: selector [str] | ms [int]
    postInteractionWait: null,
    scrollToSelector: null,
  };
  const config = Object.assign(defaults, givenScenario);

  for (const keyPressSelectorItem of config.keyPressSelectors) {
    await page.waitFor(keyPressSelectorItem.selector);
    await page.type(keyPressSelectorItem.selector, keyPressSelectorItem.keyPress);
  }

  for (const hoverSelectorItem of config.hoverSelectors) {
    await page.waitFor(hoverSelectorItem);
    await page.hover(hoverSelectorItem);
  }

  for (const clickSelectorItem of config.clickSelectors) {
    await page.waitFor(clickSelectorItem);
    await page.click(clickSelectorItem);
  }

  if (config.postInteractionWait) {
    await page.waitFor(config.postInteractionWait);
  }

  if (config.scrollToSelector) {
    await page.waitFor(config.scrollToSelector);
    await page.evaluate(scrollToSelector => {
      document.querySelector(scrollToSelector).scrollIntoView();
    }, config.scrollToSelector);
  }
};
