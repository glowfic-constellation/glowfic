class AddMoietyToUser < ActiveRecord::Migration[4.2]
  MOIETIES = {
    1 => 'AA0000',
    2 => '00BF80',
    3 => '8040BF',
    4 => 'BF8040',
    5 => 'A0A0A0',
    7 => 'C080FF',
    8 => '0080FF',
    9 => 'FFFFFF',
    12 => 'd5732a',
    15 => 'FF91BF',
    16 => 'FF8000',
    18 => '228B22',
    19 => '000000',
    20 => '62371F',
    22 => '7D0552',
    24 => 'ff5c5c',
    25 => '728C00',
    27 => '6960EC',
    30 => '000080',
    31 => '860018',
    33 => '006000',
  }
  # this constant was removed from the model but is still needed here.

  def change
    add_column :users, :moiety, :string
    User.where(id: MOIETIES.keys).each do |user|
      user.moiety = MOIETIES[user.id]
      user.save
    end
  end
end
