class CreatePgSearchDocuments < ActiveRecord::Migration
  def self.up
    say_with_time("Creating table for pg_search multisearch") do
      create_table :pg_search_documents do |t|
        t.text :content
        t.belongs_to :searchable, :polymorphic => true, :index => true
        t.timestamps null: false
      end
      execute "CREATE INDEX idx_fts_search ON pg_search_documents USING gin(to_tsvector('english', content))"
      PgSearch::Multisearch.rebuild(Post)
      PgSearch::Multisearch.rebuild(Reply)
    end
  end

  def self.down
    say_with_time("Dropping table for pg_search multisearch") do
      drop_table :pg_search_documents
    end
  end
end
