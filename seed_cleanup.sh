rake db:seed:dump MODELS_EXCLUDE=Audited::Audit,FlatPost,BoardAuthor,PostAuthor,PostView,User,Board,Tag EXCLUDE=created_at,updated_at,tagged_at,edited_at,character_group_id,has_gallery,s3_key,description,suggested,reply_order,thread_id,last_user_id,last_reply_id,authors_locked,credit,privacy


cat db/seeds.rb | perl -pe 's/\}\n/\},\n/g' > db/seeds.rb.mv
rm db/seeds.rb
mv db/seeds.rb.mv db/seeds.rb

sed -Ei 's/\{i/{ i/g' db/seeds.rb

sed -Ei 's/(\w)\}/\1 }/g' db/seeds.rb
sed -Ei 's/"\}/" }/g' db/seeds.rb

sed -Ei 's/, template_name: nil//g' db/seeds.rb
sed -Ei 's/, screenname: nil//g' db/seeds.rb
sed -Ei 's/, template_id: nil//g' db/seeds.rb
sed -Ei 's/, default_icon_id: nil//g' db/seeds.rb
sed -Ei 's/, pb: nil//g' db/seeds.rb
sed -Ei 's/, added_by_group: false//g' db/seeds.rb
sed -Ei 's/, section_order: 0 / /g' db/seeds.rb
sed -Ei 's/, owned: false//g' db/seeds.rb
sed -Ei 's/, section_id: nil//g' db/seeds.rb
sed -Ei 's/, character_id: nil//g' db/seeds.rb
sed -Ei 's/, character_alias_id: nil//g' db/seeds.rb
sed -Ei 's/, icon_id: nil//g' db/seeds.rb
sed -Ei 's/, status: 1//g'  db/seeds.rb
sed -Ei 's/(section_id: [0-9]+), /\1,\n\t\t/g'

#sed -Ei 's/ id: [0-9]+,//g' db/seeds.rb
