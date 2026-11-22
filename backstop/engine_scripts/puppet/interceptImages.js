const fs = require('fs');
const path = require('path');

// Seeded icons point at remote hosts (v.dreamwidth.org, imgur), which load slowly, unreliably or not at all
// from a container (Dreamwidth often answers 504), so the page height and content changed between runs.
// Answer every remote image request with a local file so captures are repeatable. Inline data: and blob:
// images never touch the network, so they are left alone (the gallery uploader uses a 1x1 data: GIF).
const APP_ORIGIN = 'http://web:3000/';
const readImage = (name) => fs.readFileSync(path.resolve(__dirname, '..', name));

// Remote images whose size matters to the layout get a local copy of the same size. The seeded icons
// are all shown as icons (at most 100x100), so the 100x100 stub stands in for them.
const LOCAL_COPIES = {
  'https://dummyimage.com/400x200/000/fff': { body: readImage('images/dummyimage-400x200-000-fff.png'), contentType: 'image/png' },
};
const IMAGE_STUB = { body: readImage('imageStub.jpg'), contentType: 'image/jpeg' };

module.exports = async (page) => {
  await page.setRequestInterception(true);
  page.on('request', (request) => {
    if (request.isInterceptResolutionHandled()) return;
    const url = request.url();
    if (request.resourceType() === 'image' && /^https?:/.test(url) && !url.startsWith(APP_ORIGIN)) {
      const image = LOCAL_COPIES[url] || IMAGE_STUB;
      request.respond({ status: 200, contentType: image.contentType, body: image.body });
    } else {
      request.continue();
    }
  });
};
