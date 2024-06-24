class MigrateFacecasts < ActiveRecord::Migration[7.1]
  def up
    Character.where.not(pb: nil).in_batches do |batch|
      ary = batch.pluck(:id, :pb, :user_id)
      ary.each do |id, pb, user_id|
        galleries = GalleryTag.where(character_id: id).pluck(:gallery_id)
        fcs = pb.split(/[,;] (?=[A-Z])|\//).map(&:strip)
        fcs.each do |fc|
          tag = Facecast.find_by(name: fc)
          tag = Facecast.create!(name: fc, user_id: user_id) if tag.nil?
          CharacterTag.create!(character_id: id, tag_id: tag.id)
          galleries.each { |gid| GalleryTag.create!(gallery_id: gid, tag_id: id) }
        end
      end
    end
  end

  def down
    Facecast.each(&:destroy!)
  end
end
