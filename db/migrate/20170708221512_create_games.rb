class CreateGames < ActiveRecord::Migration[5.1]
  def change
    create_table :games do |t|
      t.references :host, foreign_key: true
      t.datetime :start_time
      t.datetime :finish_time

      t.timestamps
    end
  end
end
