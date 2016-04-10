class AddMoietyToUser < ActiveRecord::Migration
  def change
    add_column :users, :moiety, :string
    User.where(id: User::MOIETIES.keys).each do |user|
      user.moiety = User::MOIETIES[user.id]
      user.save
    end
  end
end
