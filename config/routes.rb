Rails.application.routes.draw do
  localized do
    devise_for :users, controllers: { registrations: "registrations" }

    root 'dashboard#index'

    get '/sandbox', to: 'dashboard#sandbox'

    resource :account, only: [:edit, :update]
    resources :profiles, only: [:index, :update]
    resource :ieducar_api_configurations, only: [:edit, :update]
    resources :unities
  end
end
