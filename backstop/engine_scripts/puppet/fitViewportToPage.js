// BackstopJS 6 (Puppeteer 22) no longer grows the viewport when a selector capture is taller than it,
// and Backstop's own resize to the body's size doesn't help here because html and body are height: 100%,
// so element captures were cut off at the viewport height. Grow the viewport to the page height first,
// as Puppeteer 10 (BackstopJS 5) did, so captures cover the whole element again.
// Every onReadyScript must call this last (scenarios with their own onReadyScript skip onReady.js).
module.exports = async (page) => {
  const viewport = page.viewport();
  const height = await page.evaluate(() => document.documentElement.scrollHeight);
  if (height > viewport.height) await page.setViewport({ ...viewport, height });
};
