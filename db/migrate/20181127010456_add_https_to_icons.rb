class AddHttpsToIcons < ActiveRecord::Migration[5.2]
  def up
    Icon.where("url LIKE '%imgur.com%'").where("url LIKE 'http:%'").find_each do |icon|
      icon.url = icon.url.sub("http:", "https:")
      icon.save!
    end

    Icon.where("url like '%dreamwidth.org%'").where("url like 'http:%'").find_each do |icon|
      icon.url = icon.url.sub("http:", "https:")
      icon.save!
    end
  end

  def down
  end
end
