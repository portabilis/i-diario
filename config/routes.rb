Rails.application.routes.draw do
  devise_for :users

  root 'dashboard#index'

  get '/sandbox', to: 'dashboard#sandbox'

  resources :profiles, only: [:index, :update]
  resource :ieducar_api_configurations, only: [:edit, :update]
  resources :unities
end
