# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
Rails.application.config.assets.precompile += [/\w+\/*.js/]

Rails.application.config.assets.precompile << "accept_tos.js"
Rails.application.config.assets.precompile << "blocks.js"
Rails.application.config.assets.precompile << "board_sections.js"
Rails.application.config.assets.precompile << "global.js"
Rails.application.config.assets.precompile << "icons.js"
Rails.application.config.assets.precompile << "messages.js"
Rails.application.config.assets.precompile << "paginator.js"
Rails.application.config.assets.precompile << "reorder.js"

Rails.application.config.assets.precompile += %w[layouts/*.css tinymce.css]
