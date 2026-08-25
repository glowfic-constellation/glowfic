class AddDraftStatusVisibility < ActiveRecord::Migration[8.0]
  def change
    # global default: whether a user's in-progress statuses are shown to their coauthors
    add_column :users, :show_drafts_to_coauthors, :boolean, default: false

    change_table :post_authors, bulk: true do |t|
      # per-thread override of the above; nil means "use the user's default"
      t.boolean :show_drafts

      # set by an author to say they intend to keep tagging (a multitag in progress)
      t.boolean :still_tagging, default: false
    end
  end
end
