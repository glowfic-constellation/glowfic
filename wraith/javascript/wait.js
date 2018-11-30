module.exports = function (casper, ready) {
    casper.options.verbose = true;
    casper.options.logLevel = "debug"

    // make Wraith wait a bit longer before taking the screenshot
    casper.wait(10000, ready); // you MUST call the ready() callback for Wraith to continue
}
