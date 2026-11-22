const clickAndHoverHelper = require('./clickAndHoverHelper');
const fitViewportToPage = require('./fitViewportToPage');

// Pages with the rich text editor keep changing after load while TinyMCE initialises: the toolbar
// buttons start disabled and the autoresize plugin grows the editor to fit its content. Wait until
// every editor reports initialised and its size and toolbar state have stopped changing.
const waitForEditorsToSettle = (page) => page.waitForFunction(() => {
  if (!window.tinymce) return true;
  if (!window.tinymce.get().every((editor) => editor.initialized)) return false;
  const state = [...document.querySelectorAll('.tox-tinymce')].map((box) =>
    box.offsetHeight + ':' + box.querySelectorAll('.tox-tbtn--disabled, [aria-disabled="true"]').length,
  ).join('|');
  const now = Date.now();
  if (window.__backstopEditorState !== state) {
    window.__backstopEditorState = state;
    window.__backstopEditorSince = now;
    return false;
  }
  return now - window.__backstopEditorSince >= 500;
}, { timeout: 5000, polling: 100 });

module.exports = async (page, scenario, _vp) => {
  console.log('SCENARIO > ' + scenario.label);
  await waitForEditorsToSettle(page).catch(() => console.log('TinyMCE did not settle: ' + scenario.label));
  await clickAndHoverHelper(page, scenario);
  await fitViewportToPage(page);
};
