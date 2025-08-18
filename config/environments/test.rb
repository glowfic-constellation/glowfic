require "active_support/core_ext/integer/time"

# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # While tests run files are not watched, reloading is not necessary.
  config.enable_reloading = false

  # Eager loading loads your entire application. When running a single test locally,
  # this is usually not necessary, and can slow down your test suite. However, it's
  # recommended that you enable it in continuous integration systems to ensure eager
  # loading is working properly before deploying your code.
  config.eager_load = ENV["CI"].present?

  # Configure public file server for tests with cache-control for performance.
  config.public_file_server.headers = {
    "cache-control" => "public, max-age=3600",
  }

  # Show full error reports.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.cache_store = :redis_cache_store, { url: ENV.fetch('REDIS_URL', nil) }

  # Render exception templates for rescuable exceptions and raise for other exceptions.
  config.action_dispatch.show_exceptions = :rescuable

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  # config.active_storage.service = :test

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = { host: "example.com" }

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations.
  # config.i18n.raise_on_missing_translations = true

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  # Raise error when a before_action's only/except options reference missing actions.
  config.action_controller.raise_on_missing_callback_actions = true

  config.generators do |g|
    g.test_framework :rspec, fixture: true
    g.fixture_replacement :factory_bot
  end

  # Check html is valid
  config.middleware.use HTMLProofer::Middleware

  # raise an error if assets aren't found
  config.assets.unknown_asset_fallback = false
  config.assets.check_precompiled_asset = ENV["CI"].present?

  # don't use digest string
  config.assets.digest = false

  Prosopite.rails_logger = true
  Prosopite.raise = true
  # Prosopite highlights a lot of N+1 problems during a run of our test suite.
  # This configuration allow-lists the known ones, which should prevent future
  # code changes from introducing new N+1 queries unintentionally, at least.
  #
  # TODO Fix some of the below
  Prosopite.allow_stack_paths = [
    # These involve Ruby magic too deep for me to understand
    'PostsController#destroy', 'PostsController#update',
    'RepliesController#post_replies',
    'CharactersController#create', 'CharactersController#destroy',
    'BoardsController#destroy',

    # Ruby magic that seems simple but I don't want to get into it
    'app/views/galleries/_expandable.haml',

    # Perfectly possible to fix without Ruby magic but I'm not sure how
    'CharacterTag#add_galleries_to_character',
    'CharacterTag#remove_galleries_from_character',
    'CharactersController#duplicate',
    'Post#word_count_for',
    'app/views/galleries/_single.haml',

    # Theoretically simple to fix, but requires restructuring a thing
    'Post#mark_read',
    'PostsController#mark',
    'app/views/bookmarks/search.haml',
    'Post::Author.clear_cache_for',
    'app/views/reports/_monthly.haml',

    # Requires replacing a use of #pick
    'app/views/characters/_icon_view.haml',
    'app/views/characters/_list_section.haml',

    # The fault lies in a 3rd party gem
    'app/views/writable/_history.haml',

    # Definitely solvable but I need to think about multi replies
    'RepliesController#preview_replies',
    'RepliesController#edit_multi_replies',

    # Background jobs can have a little inefficiency, as a treat
    'app/jobs/', 'app/services/',

    # Not yet evaluated
    # TODO look at these in detail
    'GalleryTag#add_gallery_to_characters',
    'Character#valid_galleries',
    'IconsController#delete_multiple',
    'Gallery#character_gallery_for',
  ]
end
