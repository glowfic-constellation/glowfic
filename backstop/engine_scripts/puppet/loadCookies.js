const fs = require('fs');

module.exports = async (page, scenario) => {
  let cookies = [];
  const cookiePath = scenario.cookiePath;

  // READ COOKIES FROM FILE IF EXISTS
  if (fs.existsSync(cookiePath)) {
    cookies = JSON.parse(fs.readFileSync(cookiePath));
  } else {
    console.log('Cookies not found.')
  }

  // SET COOKIES
  const setCookies = async () => {
    return Promise.all(
      cookies.map(async (cookie) => {
        await page.setCookie(cookie);
      })
    );
  };
  await setCookies();
  //console.log('Cookie state restored with:', JSON.stringify(cookies, null, 2));
};
