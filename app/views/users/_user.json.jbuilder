json.extract! user, :id, :vk, :telegram, :name, :surname, :online, :created_at, :updated_at
json.url user_url(user, format: :json)
