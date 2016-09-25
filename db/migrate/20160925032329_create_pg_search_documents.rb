class CreatePgSearchDocuments < ActiveRecord::Migration
  def self.up
    execute "CREATE INDEX idx_fts_post_content ON posts USING gin(to_tsvector('english', content))"
    execute "CREATE INDEX idx_fts_post_subject ON posts USING gin(to_tsvector('english', subject))"
    execute "CREATE INDEX idx_fts_reply_content ON replies USING gin(to_tsvector('english', content))"
  end

  def self.down
    execute "DROP INDEX idx_fts_post_content"
    execute "DROP INDEX idx_fts_post_subject"
    execute "DROP INDEX idx_fts_reply_content"
  end
end
