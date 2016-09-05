require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'

  localized do
    devise_for :users

    # ***REMOVED***
    namespace :v1 do
      resources :access do
        collection do
          post :request_access
          post :send_access
          post :send_access_batch
        end
      end
      resources :command do
        collection do
          post :request_command
        end
      end
      resources :biometric do
        collection do
          post :send_biometric
          post :request_biometric
          post '/request_biometric/:id', to: 'biometric#request_biometric_by_id'
        end
      end
    end

    namespace :api do
      namespace :v1 do
        resources :***REMOVED***, only: [:create]
        resources :exam_rules, only: [:index]
        resources :teacher_unities, only: [:index]
        resources :teacher_classrooms, only: [:index]
        resources :teacher_disciplines, only: [:index]
        resources :school_calendars, only: [:index]
        resources :daily_frequencies, only: [:create]
        resources :***REMOVED***, only: [:create]
        resources :daily_frequency_students, only: [:update]
      end
    end

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
        get :employees
        post :employees
      end
    end

    resources :students do
      collection do
        get :search_api
        get :in_recovery, path: '/in_recovery/classrooms/:classroom_id/disciplines/:discipline_id/school_calendar_steps/:school_calendar_step_id'
        get :in_final_recovery, path: '/in_final_recovery/classrooms/:classroom_id/disciplines/:discipline_id'
      end
    end

    resources :teachers, only: :index
    resources :***REMOVED***, only: :index
    resources :***REMOVED***, only: :index

    root 'dashboard#index'

    get '/sandbox', to: 'dashboard#sandbox'
    get '/current_role/:id', to: 'current_role#set', as: :set_current_role
    get '/current_role', to: 'current_role#index', as: :current_roles
    get '/system_***REMOVED***/read_all', to: 'system_***REMOVED***#read_all', as: :read_all_***REMOVED***
    get '/disabled_entity', to: 'pages#disabled_entity'
    get '/new_role_modal_feature', to: 'news#role_modal_feature'

    resources :messages, except: [:edit, :update] do
      collection do
        delete :destroy_batch
      end
    end
    resources :users, concerns: :history do
      collection do
        get :export_all
        get :export_selected
      end
    end

    resource :account, only: [:edit, :update]
    resources :roles do
      member do
        get :history
      end
    end
    resources :***REMOVED***, only: [:index]
    resources :***REMOVED***, only: [:index, :show]
    resources :***REMOVED***_confirmations, except: [:new, :create] do
      member do
        patch :cancel
        patch :preview
        patch :confirm
      end
    end
    resource :***REMOVED***_configs, only: [:edit, :update], concerns: :history
    resources :***REMOVED***s, concerns: :history
    resource :ieducar_api_configurations, only: [:edit, :update], concerns: :history do
      resources :synchronizations, only: [:index, :create]
    end
    resource :contact_school, only: [:new, :create]
    resource :notification, only: [:edit, :update], concerns: :history
    resource :general_configurations, only: [:edit, :update], concerns: :history
    resource :entity_configurations, only: [:edit, :update], concerns: :history
    resources :backup_files, only: [:index, :create]
    resources :unities, concerns: :history do
      collection do
        delete :destroy_batch
        get :synchronizations
        post :create_batch
        get :search
        get :all
        get :school_group
      end
    end
    resources :***REMOVED***, concerns: :history do
      get '***REMOVED***_classes/select'
    end

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
    resources :***REMOVED***, concerns: :history
    resources :***REMOVED***s, concerns: :history
    resources :***REMOVED***, concerns: :history
    resources :***REMOVED***, concerns: :history
    resources :courses, only: [:index]
    resources :lectures, only: [:index]

    resources :grades, only: [:index] do
      member do
        get :verify_candidate_birthdate
      end
    end

    resources :schools, only: [:index]
    resources :***REMOVED***, concerns: :history
    resources :***REMOVED***, concerns: :history
    resources :authorization_***REMOVED***, concerns: :history

    resources :moved_***REMOVED***, only: [:index]
    get '/unities/:unity_id/moved_***REMOVED***/:material_id', to: 'moved_***REMOVED***#show', as: 'unity_moved_material'

    resources :***REMOVED***, only: [:index, :new, :create]
    get '/***REMOVED***/entrances/:id', to: '***REMOVED***#show_entrance', as: 'inventory_adjustment_entrance'
    get '/***REMOVED***/exits/:id', to: '***REMOVED***#show_exit', as: 'inventory_adjustment_exit'

    resources :***REMOVED***, concerns: :history

    resources :test_settings, concerns: :history do
      resources :test_setting_tests, only: [:index]
    end
    resources :test_setting_tests, only: [:index, :show]

    resources :school_calendars, concerns: :history do
      collection do
        get  :synchronize
        post :create_and_update_batch
      end

      resources :school_calendar_steps, only: [:index]
      resources :school_calendar_events, concerns: :history do
        collection do
          get  :grades
          get  :classrooms
        end
      end
    end
    resources :school_calendar_steps, only: [:show]

    resources :discipline_teaching_plans, concerns: :history
    resources :knowledge_area_teaching_plans, concerns: :history
    resources :discipline_lesson_plans, concerns: :history
    resources :knowledge_area_lesson_plans, concerns: :history
    resources :discipline_content_records, concerns: :history
    resources :knowledge_area_content_records, concerns: :history
    resources :classrooms, only: [:index, :show] do
      resources :students, only: [:index]
    end
    resources :contents, only: :index
    resources :disciplines, only: [:index] do
      collection do
        get :search
      end
    end
    resources :knowledge_areas, only: [:index]
    resources :exam_rules, only: [:index]
    resources :avaliations, concerns: :history do
      collection do
        get :search
      end
    end
    resources :teacher_avaliations, only: :index
    resources :daily_notes, only: [:new, :create, :edit, :update, :destroy], concerns: :history
    resources :daily_note_students, only: [:index] do
      collection do
        get :old_notes
      end
    end
    resources :school_term_recovery_diary_records, concerns: :history
    resources :transfer_notes, concerns: :history do
      collection do
        get :current_notes
      end
    end
    resources :final_recovery_diary_records, concerns: :history
    resources :avaliation_recovery_diary_records, concerns: :history
    resources :conceptual_exams, concerns: :history
    resources :descriptive_exams, only: [:new, :create, :edit, :update]
    resources :daily_frequencies, only: [:new, :create], concerns: :history do
      collection do
        get :edit_multiple
        put :update_multiple
        delete :destroy_multiple
      end
    end
    resources :absence_justifications, concerns: :history
    resources :observation_diary_records, expect: :show, concerns: :history
    resources :ieducar_api_exam_postings
    resources :avaliation_exemptions, concerns: :history
    resources :***REMOVED***, concerns: :history

    get '/reports/attendance_record', to: 'attendance_record_report#form', as: 'attendance_record_report'
    post '/reports/attendance_record', to: 'attendance_record_report#report', as: 'attendance_record_report'

    get '/reports/absence_justification', to: 'absence_justification_report#form', as: 'absence_justification_report'
    post '/reports/absence_justification', to: 'absence_justification_report#report', as: 'absence_justification_report'

    get '/reports/exam_record', to: 'exam_record_report#form', as: 'exam_record_report'
    post '/reports/exam_record', to: 'exam_record_report#report', as: 'exam_record_report'

    get '/reports/observation_record', to: 'observation_record_report#form', as: 'observation_record_report'
    post '/reports/observation_record', to: 'observation_record_report#report', as: 'observation_record_report'

    get '/reports/***REMOVED***', to: '***REMOVED***#form', as: '***REMOVED***'
    post '/reports/***REMOVED***', to: '***REMOVED***#report', as: '***REMOVED***'

    get '/reports/discipline_lesson_plan', to: 'discipline_lesson_plan_report#form', as: 'discipline_lesson_plan_report'
    post '/reports/discipline_lesson_plan', to: 'discipline_lesson_plan_report#report', as: 'discipline_lesson_plan_report'

    get '/reports/knowledge_area_lesson_plan', to: 'knowledge_area_lesson_plan_report#form', as: 'knowledge_area_lesson_plan_report'
    post '/reports/knowledge_area_lesson_plan', to: 'knowledge_area_lesson_plan_report#report', as: 'knowledge_area_lesson_plan_report'


    get '/reports/teacher_report_cards', to: 'teacher_report_cards#form', as: 'teacher_report_cards'
    post '/reports/teacher_report_cards', to: 'teacher_report_cards#report', as: 'teacher_report_cards'

    post '/food_composition', to: 'food_composition#calculate'
  end
end
