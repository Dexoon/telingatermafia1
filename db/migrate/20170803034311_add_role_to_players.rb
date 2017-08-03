class AddRoleToPlayers < ActiveRecord::Migration[5.1]
  def change
    add_column :players, :role, :string
  end
end
