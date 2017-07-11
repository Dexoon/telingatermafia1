class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.integer :vk
      t.integer :telegram
      t.string :name
      t.string :surname
      t.boolean :online

      t.timestamps
    end
  end
end
