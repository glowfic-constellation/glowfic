def migrate
  Icon.where(s3_key: true).limit(1000).ids do |icon_id|
    MigrateUploadJob.enque(icon_id)
  end
end

migrate if $PROGRAM_NAME == __FILE__
