require 'sidekiq/web'

Rails.application.routes.draw do
  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
  end

  localized do
    devise_for :users

    resources :registrations do
      collection do
        get :parents
      end
    end

    resources :students do
      collection do
        get :search_api
      end
    end

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
    resources :***REMOVED***_classes
    resources :***REMOVED***
    resources :***REMOVED***
    resources :***REMOVED***
    resources :***REMOVED***
    resources :***REMOVED*** do
      resources :material_request_items, only: [:index]
    end
    resources :***REMOVED***
  end
end
