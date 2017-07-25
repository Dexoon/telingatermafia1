class AddRatingToGames < ActiveRecord::Migration[5.1]
  def change
    add_column :games, :rating, :boolean, default: false
  end
end
