json.extract! message, :id, :game, :chat_id, :message_id, :aasm_state, :created_at, :updated_at
json.url message_url(message, format: :json)
