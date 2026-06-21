class SeedBuiltinSkins < ActiveRecord::Migration[8.0]
  # The existing built-in layouts, exposed as forkable public skins so the
  # gallery launches with content people can copy and tweak. Maps the layout
  # asset slug to its display name.
  BUILTIN = {
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

  def up
    owner = User.find_by(role_id: Permissible::ADMIN) || User.order(:id).first
    return say('No users found; skipping built-in skin seed.') unless owner

    assets = Rails.application.assets
    return say('Asset environment unavailable; skipping built-in skin seed.') unless assets

    BUILTIN.each do |slug, name|
      skin_name = "#{name}#{SUFFIX}"
      next if Skin.exists?(name: skin_name, user_id: owner.id)

      asset = assets.find_asset("layouts/#{slug}.css")
      next say("Could not compile layouts/#{slug}.css; skipping.") unless asset

      Skin.create!(
        user: owner,
        name: skin_name,
        description: "The built-in #{name} theme, as a forkable skin.",
        public: true,
        css: asset.to_s,
      )
      say("Seeded built-in skin: #{skin_name}")
    end
  end

  def down
    Skin.where('name LIKE ?', "%#{SUFFIX}").destroy_all
  end
end
