Rails.application.routes.draw do
  resources :players
  resources :games
  resources :users

  get '/online', to: 'users#online'
  get '/change_status', to: 'users#change_status'
  get '/name', to: 'users#name'
  get '/online_list', to: 'users#online_list'

  get '/start_game', to: 'games#start_game'
  get '/set_score', to: 'players#set_score'
  get '/score', to: 'players#score'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
