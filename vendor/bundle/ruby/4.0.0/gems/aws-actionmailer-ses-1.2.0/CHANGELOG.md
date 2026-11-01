1.2.0 (2026-05-21)
------------------

* Feature - Add support for `configuration_set_name` (#11), `email_tags` (#8), and `list_management_options` in SES V2 delivery settings.

1.1.0 (2026-03-31)
------------------

* Feature - Support injecting a preconstructed client via `:ses_client` and `:sesv2_client` options.

1.0.0 (2024-11-21)
------------------

* Feature - [Major Version] Register ActionMailers with a Railtie and allow for configuration using `config.action_mailer.ses_v2_settings` and `config.action_mailer.ses_settings`.

0.1.0 (2024-11-16)
------------------

* Feature - Initial version of this gem.
