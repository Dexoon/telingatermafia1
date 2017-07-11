json.extract! player, :id, :position, :user_id, :game_id, :score, :created_at, :updated_at
json.url player_url(player, format: :json)
