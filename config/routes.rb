require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'

  get 'worker-processses-status', to: 'sidekiq_monitor#processes_status'

  localized do
    devise_for :users

    # madis
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
        resources :exam_rules, only: [:index]
        resources :teacher_unities, only: [:index]
        resources :teacher_classrooms, only: [:index]
        resources :teacher_disciplines, only: [:index]
        resources :school_calendars, only: [:index]
        resources :daily_frequencies, only: [:create]
        resources :daily_frequency_students, only: [:update]
      end
      namespace :v2 do
        resources :exam_rules, only: [:index]
        get 'step_activity', to: 'step_activity#check'
        resources :teacher_unities, only: [:index]
        resources :teacher_classrooms, only: [:index]
        resources :teacher_disciplines, only: [:index]
        resources :school_calendars, only: [:index]
        resources :daily_frequencies, only: [:create, :index]
        resources :daily_frequency_students, only: [:update] do
          collection do
            post :update_or_create
          end
        end
        resources :classroom_students, only: [:index]
        resources :teacher_allocations, only: [:index]
        resources :lesson_plans, only: [:index]
        resources :content_records, only: [:index] do
          collection do
            get :lesson_plans
            post :sync
          end
        end
        resources :teaching_plans, only: [:index]
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
        get :in_recovery
        get :in_final_recovery, path: '/in_final_recovery/classrooms/:classroom_id/disciplines/:discipline_id'
      end
    end

    resources :teachers, only: :index

    resources :system_notifications, only: :index

    root 'dashboard#index'

    namespace :dashboard do
      resources :student_partial_scores, only: [:index]
      resources :teacher_next_avaliations, only: [:index]
      resources :teacher_pending_avaliations, only: [:index]
      resources :teacher_work_done_chart, only: [:index]
    end

    patch '/current_role', to: 'current_role#set', as: :set_current_role
    post '/system_notifications/read_all', to: 'system_notifications#read_all', as: :read_all_notifications
    get '/disabled_entity', to: 'pages#disabled_entity'
    get '/new_role_modal_feature', to: 'news#role_modal_feature'

    resources :users, concerns: :history do
      collection do
        get :export_all
        get :export_selected
        get :select2_remote
      end
    end

    resource :account, only: [:edit, :update]
    resources :roles do
      member do
        get :history
      end
    end
    resources  :user_roles, only: [:show]
    resource :ieducar_api_configurations, only: [:edit, :update], concerns: :history do
      resources :synchronizations, only: [:index, :create]
    end
    resource :general_configurations, only: [:edit, :update], concerns: :history
    resource :entity_configurations, only: [:edit, :update], concerns: :history
    resource :terms_dictionaries, only: [:edit, :update], concerns: :history
    resources :admin_synchronizations, only: [:index]
    resources :backup_files, only: [:index, :create]
    resources :unities, concerns: :history do
      collection do
        delete :destroy_batch
        get :synchronizations
        post :create_batch
        get :search
        get :all
        get :select2_remote
      end
    end
    resources :courses, only: [:index]
    resources :lectures, only: [:index]
    resources :maintenance_adjustments, concerns: :history, except: :show do
      collection do
        get :any_completed
      end
    end

    resources :grades, only: [:index]

    resources :schools, only: [:index]

    resources :custom_rounding_tables, concerns: :history, except: :show
    resources :custom_rounding_tables, concerns: :history, except: :show

    resources :test_settings, concerns: :history do
      resources :test_setting_tests, only: [:index]
    end
    resources :test_setting_tests, only: [:index, :show]

    resources :school_calendars, concerns: :history do
      collection do
        get :step
        get :synchronize
        post :create_and_update_batch
        get :years_from_unity
      end

      resources :school_calendar_steps, only: [:index]
      resources :school_calendar_events, concerns: :history do
        collection do
          get  :grades
          get  :classrooms
        end
      end
    end
    resources :school_calendar_steps, only: [:show, :index]
    resources :school_calendar_classroom_steps, only: [:show, :index]

    resources :discipline_teaching_plans, concerns: :history
    resources :knowledge_area_teaching_plans, concerns: :history
    resources :discipline_lesson_plans, concerns: :history do
      collection do
        post :clone
      end
    end
    resources :knowledge_area_lesson_plans, concerns: :history do
      collection do
        post :clone
      end
    end
    resources :discipline_content_records, concerns: :history do
      collection do
        post :clone
      end
    end
    resources :knowledge_area_content_records, concerns: :history do
      collection do
        post :clone
      end
    end
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
        get :multiple_classrooms
        post :create_multiple_classrooms
      end
    end
    resources :complementary_exam_settings, concerns: :history
    resources :complementary_exams, concerns: :history do
      collection do
        get :settings
      end
    end
    resources :teacher_avaliations, only: :index
    resources :daily_notes, only: [:index, :new, :create, :edit, :update, :destroy], concerns: :history do
      collection do
        get :search
      end
    end
    resources :daily_note_students, only: [:index] do
      collection do
        get :old_notes
        get :dependence
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
    resources :conceptual_exams, concerns: :history do
      collection do
        get :exempted_disciplines
        get :find_conceptual_exam_by_student
      end
    end
    resources :old_steps_conceptual_values, except: [:only]
    resources :descriptive_exams, only: [:new, :create, :edit, :update], concerns: :history do
      collection do
        get :opinion_types
      end
    end
    resources :daily_frequencies, only: [:new, :create], concerns: :history do
      collection do
        get :edit_multiple
        put :update_multiple
        delete :destroy_multiple
      end
    end
    get 'daily_frequency/history_multiple', to: 'daily_frequencies#history_multiple', as: 'history_multiple_daily_frequency'

    resources :absence_justifications, concerns: :history
    resources :observation_diary_records, expect: :show, concerns: :history
    resources :ieducar_api_exam_postings do
      member do
        get :done_percentage
      end
    end
    resources :avaliation_exemptions, concerns: :history

    resources :daily_frequency_students do
      collection do
        post :create_or_update
      end
    end

    resources :student_enrollments, only: [:index]
    resources :student_enrollments_lists, only: [:index] do
      collection do
        get :by_date
        get :by_date_range
      end
    end

    get '/reports/attendance_record', to: 'attendance_record_report#form', as: 'attendance_record_report'
    post '/reports/attendance_record', to: 'attendance_record_report#report', as: 'attendance_record_report'

    get '/reports/absence_justification', to: 'absence_justification_report#form', as: 'absence_justification_report'
    post '/reports/absence_justification', to: 'absence_justification_report#report', as: 'absence_justification_report'

    get '/reports/exam_record', to: 'exam_record_report#form', as: 'exam_record_report'
    post '/reports/exam_record', to: 'exam_record_report#report', as: 'exam_record_report'

    get '/reports/partial_score_record', to: 'partial_score_record_report#form', as: 'partial_score_record_report'
    post '/reports/partial_score_record', to: 'partial_score_record_report#report', as: 'exam_record_report'

    get '/reports/observation_record', to: 'observation_record_report#form', as: 'observation_record_report'
    post '/reports/observation_record', to: 'observation_record_report#report', as: 'observation_record_report'

    get '/reports/discipline_lesson_plan', to: 'discipline_lesson_plan_report#form', as: 'discipline_lesson_plan_report'
    post '/reports/discipline_lesson_plan', to: 'discipline_lesson_plan_report#lesson_plan_report', as: 'discipline_lesson_plan_report'
    post '/reports/discipline_content_record', to: 'discipline_lesson_plan_report#content_record_report', as: 'discipline_content_record_report'

    get '/reports/knowledge_area_lesson_plan', to: 'knowledge_area_lesson_plan_report#form', as: 'knowledge_area_lesson_plan_report'
    post '/reports/knowledge_area_lesson_plan', to: 'knowledge_area_lesson_plan_report#lesson_plan_report', as: 'knowledge_area_lesson_plan_report'
    post '/reports/knowledge_area_content_record', to: 'knowledge_area_lesson_plan_report#content_record_report', as: 'knowledge_area_content_record_report'

    get '/reports/teacher_report_cards', to: 'teacher_report_cards#form', as: 'teacher_report_cards'
    post '/reports/teacher_report_cards', to: 'teacher_report_cards#report', as: 'teacher_report_cards'

    resources :data_exportations, only: [:index, :create]
  end

  match '/404', to: 'errors#not_found', via: :all
  match '/422', to: 'errors#unprocessable_entity', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
end
