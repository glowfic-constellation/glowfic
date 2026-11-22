# Fails any :js system spec when the page raised an uncaught JavaScript error or an unhandled
# promise rejection (including script-level SyntaxErrors such as a redeclared const from loading a
# file twice), which Selenium otherwise ignores. Errors are stored in sessionStorage so they
# survive navigation. Opt out of one example with `js_errors: :allow`.
module JsErrorHelper
  STORAGE_KEY = '__spec_js_errors'

  COLLECTOR = <<~JS
    (function() {
      function record(kind, message, source, line) {
        try {
          var errors = JSON.parse(sessionStorage.getItem('#{STORAGE_KEY}') || '[]');
          errors.push(kind + ': ' + message + ' (' + (source || '') + ':' + (line || 0) + ')');
          sessionStorage.setItem('#{STORAGE_KEY}', JSON.stringify(errors));
        } catch (e) { /* storage unavailable (e.g. about:blank) */ }
      }
      window.addEventListener('error', function(event) {
        if (event.target && event.target !== window) return; // resource load failures are not script errors
        record('error', event.message, event.filename, event.lineno);
      });
      window.addEventListener('unhandledrejection', function(event) {
        record('unhandledrejection', String(event.reason && event.reason.message || event.reason), '', 0);
      });
    })();
  JS

  def install_js_error_collector
    page.driver.browser.execute_cdp('Page.addScriptToEvaluateOnNewDocument', source: COLLECTOR)
  end

  def collected_js_errors
    JSON.parse(page.evaluate_script("sessionStorage.getItem('#{STORAGE_KEY}') || '[]'"))
  rescue Selenium::WebDriver::Error::WebDriverError
    []
  end
end
