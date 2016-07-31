class UseCloudfrontUrl < ActiveRecord::Migration
  def up
    uploaded_icons = Icon.where("url like 'http://glowfic-constellation.s3.amazonaws.com%'")
    uploaded_icons.each do |icon|
      new_url = icon.url.sub("http://glowfic-constellation.s3.amazonaws.com", "https://d1anwqy6ci9o1i.cloudfront.net")
      icon.url = new_url
      icon.save
    end
  end

  def down
    uploaded_icons = Icon.where("url like 'https://d1anwqy6ci9o1i.cloudfront.net%'")
    uploaded_icons.each do |icon|
      new_url = icon.url.sub("https://d1anwqy6ci9o1i.cloudfront.net", "http://glowfic-constellation.s3.amazonaws.com")
      icon.url = new_url
      icon.save
    end
  end
end
