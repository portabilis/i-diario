require 'sidekiq/web'

Rails.application.routes.draw do
  authenticate :user do
    mount Sidekiq::Web => '/sidekiq'
  end

  localized do
    devise_for :users

    concern :history do
      member do
        get :history
      end
    end

    resources :registrations do
      collection do
        get :parents
        get :students
        post :students
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
    resource :ieducar_api_configurations, only: [:edit, :update], concerns: :history do
      resources :syncronizations, only: [:index, :create]
    end
    resource :notification, only: [:edit, :update], concerns: :history
    resource :general_configurations, only: [:edit, :update], concerns: :history
    resources :unities, concerns: :history
    resources :***REMOVED***, concerns: :history
    resources :***REMOVED***_classes, concerns: :history
    resources :***REMOVED***, concerns: :history
    resources :***REMOVED***, concerns: :history
    resources :***REMOVED***, concerns: :history
    resources :***REMOVED***, concerns: :history
    resources :***REMOVED***, concerns: :history do
      resources :material_request_items, only: [:index]
    end
    resources :***REMOVED***, concerns: :history do
      resources :material_request_authorization_items, only: [:index]
    end
    resources :***REMOVED***, concerns: :history do
      resources :material_exit_items, only: [:index]
    end
    resources :***REMOVED***, concerns: :history
    resources :***REMOVED***, concerns: :history
    resources :***REMOVED***s, concerns: :history
    resources :***REMOVED***, concerns: :history
    resources :lectures, only: [:index]
    resources :grades, only: [:index]
  end
end
