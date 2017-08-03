class CreateMessages < ActiveRecord::Migration[5.1]
  def change
    create_table :messages do |t|
      t.references :game, foreign_key: true
      t.integer :chat_id
      t.integer :message_id
      t.string :aasm_state

      t.timestamps
    end
  end
end
