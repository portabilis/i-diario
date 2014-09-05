Rails.application.routes.draw do
  devise_for :users

  root 'dashboard#index'

  get '/sandbox', to: 'dashboard#sandbox'

  resources :profiles, only: [:index, :update]

  resources :unities
end
