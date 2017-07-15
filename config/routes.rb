Rails.application.routes.draw do
  resources :players
  resources :games
  resources :users

  get '/user', to: 'users#user'
  get '/change_status', to: 'users#change_status'
  get '/online_list', to: 'users#online_list'

  get '/player', to: 'player#player'
  get '/set_score', to: 'players#set_score'

  get '/start_game', to: 'games#start_game'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
