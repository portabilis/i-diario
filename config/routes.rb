Rails.application.routes.draw do
  devise_for :users

  resources :profiles, only: [:index, :update]

  get '/sandbox', to: 'dashboard#sandbox'

  root 'dashboard#index'
end
