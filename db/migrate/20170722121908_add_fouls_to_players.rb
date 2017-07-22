class AddFoulsToPlayers < ActiveRecord::Migration[5.1]
  def change
    add_column :players, :fouls, :integer, default: 0
    add_column :users, :pending_fouls, :integer, default: 0
    add_column :users, :newbie, :boolean, default: true
  end
end
