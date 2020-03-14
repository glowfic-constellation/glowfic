const fs = require('fs');
const { promisify } = require('util');
const readFile = promisify(fs.readFile);

module.exports = async (page, scenario) => {
  let cookies = [];
  const cookiePath = scenario.cookiePath;

  // READ COOKIES
  try {
    const cookieString = await readFile(cookiePath);
    cookies = JSON.parse(cookieString);
  } catch (e) {
    console.log('Cookies not found.');
  }

  // SET COOKIES
  const setCookies = () => {
    return Promise.all(
      cookies.map(async (cookie) => {
        await page.setCookie(cookie);
      })
    );
  };
  await setCookies();
  // console.log('Cookie state restored with:', JSON.stringify(cookies, null, 2));
};
