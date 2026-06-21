# frozen_string_literal: true

# Seeds the bundled layouts as forkable, pre-approved public skins so the
# gallery launches with content. Lives outside migrations on purpose: it needs
# the final schema and the compiled CSS, and in production assets are only
# available as precompiled files (config.assets.compile is false), not through a
# live Sprockets environment. Invoked from the `skins:seed_builtin` rake task.
module Glowfic::BuiltinSkins
  # layout asset slug => display name
  LAYOUTS = {
    'dark'           => 'Dark',
    'iconless'       => 'Iconless',
    'starry'         => 'Starry',
    'starrydark'     => 'Starry Dark',
    'starrylight'    => 'Starry Light',
    'monochrome'     => 'Monochrome',
    'river'          => 'Milky River',
    'pesterchum'     => 'Pesterchum',
    'pesterchummemo' => 'Pesterchum Memo',
  }.freeze

  SUFFIX = ' (built-in)'

  module_function

  # owner: the User to own the skins (defaults to the first admin, else first user)
  # css_loader: callable slug -> css string (injectable for tests)
  # Returns the number of skins created.
  def seed!(owner: default_owner, css_loader: method(:compiled_css), logger: nil)
    raise 'No owner available to own the built-in skins' unless owner

    created = 0
    LAYOUTS.each do |slug, name|
      skin_name = "#{name}#{SUFFIX}"
      next if Skin.exists?(name: skin_name, user_id: owner.id)

      css = css_loader.call(slug)
      if css.blank?
        logger&.call("Could not load CSS for layouts/#{slug}; skipping.")
        next
      end

      skin = Skin.create!(
        user: owner,
        name: skin_name,
        description: "The built-in #{name} theme, as a forkable skin.",
        public: true,
        css: css,
      )
      # Built-in CSS is trusted, so pre-approve it to serve raw to readers.
      skin.approve!(owner)
      created += 1
      logger&.call("Seeded built-in skin: #{skin_name}")
    end
    created
  end

  def default_owner
    User.find_by(role_id: Permissible::ADMIN) || User.order(:id).first
  end

  # Compiled CSS for a layout, working both in development (live Sprockets) and
  # production (read the digest-stamped file from the precompiled manifest).
  def compiled_css(slug)
    logical = "layouts/#{slug}.css"

    if (env = Rails.application.assets)
      env.find_asset(logical)&.to_s
    else
      manifest = Rails.application.assets_manifest
      digested = manifest.assets[logical]
      return unless digested

      path = File.join(manifest.dir, digested)
      File.read(path) if File.exist?(path)
    end
  end
end
