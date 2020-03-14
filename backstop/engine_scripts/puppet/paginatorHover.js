module.exports = async (page, _scenario) => {
  const selector = '.pagination a';
  try {
    await page.waitForSelector(selector, { timeout: 1000 });
    await page.hover(selector);
  } catch (error) { /* ignore the error this throws if the selctor doesn't exist, which it won't on mobile */ }
};
