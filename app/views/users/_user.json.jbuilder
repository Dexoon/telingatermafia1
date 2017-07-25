json.extract! user, :id, :vk, :telegram, :name, :surname, :online, :pending_fouls, :newbie, :created_at, :updated_at
json.url user_url(user, format: :json)
