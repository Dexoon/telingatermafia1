class AddAasmStateToGames < ActiveRecord::Migration[5.1]
  def change
    add_column :games, :aasm_state, :string
    change_column :players, :score, :integer, default: 0
  end
end
