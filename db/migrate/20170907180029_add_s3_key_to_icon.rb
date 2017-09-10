class AddS3KeyToIcon < ActiveRecord::Migration
  CLOUDFRONT_URL = 'https://d1anwqy6ci9o1i.cloudfront.net/'

  def self.up
    add_column :icons, :s3_key, :string

    index = CLOUDFRONT_URL.size
    Icon.where("url LIKE '#{CLOUDFRONT_URL}%'").each do |icon|
      key = icon.url[index..-1]
      url = icon.url[0...index] + ERB::Util.url_encode(key)

      icon.s3_key = key
      icon.url = url
      icon.save!
    end
  end

  def self.down
    Icon.where('s3_key is not null').each do |icon|
      icon.url = CLOUDFRONT_URL + icon.s3_key
      icon.save!
    end

    remove_column :icons, :s3_key
  end
end
