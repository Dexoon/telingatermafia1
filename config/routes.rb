Rails.application.routes.draw do
  resources :players
  resources :games
  resources :users

  get '/online/:id', to: 'users#online'
  get '/change_status/:id', to: 'users#change_status'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
