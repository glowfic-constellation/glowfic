require 'factory_girl_rails'

# make 5 boards so site_testing doesn't screw up tests
5.times do
  user = FactoryGirl.create(:user)
  board = FactoryGirl.create(:board, creator: user)
  board.destroy
  user.destroy
end
