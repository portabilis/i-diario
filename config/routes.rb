require 'sidekiq/web'

Rails.application.routes.draw do
  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
  end

  localized do
    devise_for :users, controllers: { registrations: "registrations" }

    root 'dashboard#index'

    get '/sandbox', to: 'dashboard#sandbox'

    resource :account, only: [:edit, :update]
    resources :profiles, only: [:index, :update]
    resources :disciplinary_incidents, only: [:index]
    resources :***REMOVED***, only: [:index, :show]
    resource :ieducar_api_configurations, only: [:edit, :update] do
      resources :syncronizations, only: [:index, :create]
    end
    resources :unities
    resources :***REMOVED***
  end
end
