# How to contribute

Pull requests welcome! Please try to make them as complete and clear as possible, with reproduction steps and good tests.


## Issues

Issues are monitored and responded to, but pull requests are much more likely to be merged.

Make sure the issue includes version information, reproduction steps, and any other relevant information.

You can use the `examples/sample_app.rb` to help reproduce the issue.


## Pull Requests

All PRs with changes will be reviewed and merged if possible. Thank you for taking the time to contribute.

Changes must include tests. Please include a description of the problem and why the change is needed. Same with issues, reproduction steps are helpful.


### Running the tests

```bash
bundle install
bundle exec rake test
```

And running the linting with [standard](https://github.com/standardrb/standard):

```bash
bundle exec standardrb
```
