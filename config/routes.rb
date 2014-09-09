Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "registrations" }

  root 'dashboard#index'

  resource :account, only: [:edit, :update]

  get '/sandbox', to: 'dashboard#sandbox'

  resources :profiles, only: [:index, :update]
  resource :ieducar_api_configurations, only: [:edit, :update]
  resources :unities
end
