class CreatePlayers < ActiveRecord::Migration[5.1]
  def change
    create_table :players do |t|
      t.integer :position
      t.references :user, foreign_key: true
      t.references :game, foreign_key: true
      t.integer :score

      t.timestamps
    end
  end
end
