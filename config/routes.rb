require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'

  get 'worker-processses-status', to: 'sidekiq_monitor#processes_status'

  localized do
    devise_for :users, controllers: {
      sessions: 'users/sessions',
      passwords: 'users/passwords',
      unlocks: 'users/unlocks'
    }

    namespace :api do
      namespace :v2 do
        resources :exam_rules, only: [:index]
        get 'step_activity', to: 'step_activity#check'
        get 'discipline_activity', to: 'discipline_activity#check'
        get 'student_activity', to: 'student_activity#check'
        resources :teacher_unities, only: [:index]
        resources :teacher_classrooms, only: [:index] do
          collection do
            get :has_activities
          end
        end
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
        get :select2_remote
        get :in_final_recovery, path: '/in_final_recovery/classrooms/:classroom_id/disciplines/:discipline_id'
      end
    end

    resources :teachers, only: :index do
      collection do
        get :select2
      end
    end

    resources :teacher_profiles, only: :index

    resources :system_notifications, only: :index

    root 'dashboard#index'

    namespace :dashboard do
      resources :student_partial_scores, only: [:index]
      resources :teacher_next_avaliations, only: [:index]
      resources :teacher_pending_avaliations, only: [:index]
      resources :teacher_work_done_chart, only: [:index]
    end

    post '/current_role', to: 'current_role#set', as: :set_current_role
    get '/current_role/available_classrooms', to: 'current_role#available_classrooms', as: :available_classrooms
    get '/current_role/available_disciplines', to: 'current_role#available_disciplines', as: :available_disciplines
    get '/current_role/available_school_years', to: 'current_role#available_school_years', as: :available_school_years
    get '/current_role/available_teachers', to: 'current_role#available_teachers', as: :available_teachers
    get '/current_role/available_unities', to: 'current_role#available_unities', as: :available_unities
    get '/current_role/available_teacher_profiles', to: 'current_role#available_teacher_profiles', as: :available_teacher_profiles
    get '/steps_by_school_term_type_id', to: 'school_term_type_steps#steps', as: :steps_by_school_term_type_id
    post '/system_notifications/read_all', to: 'system_notifications#read_all', as: :read_all_notifications
    get '/disabled_entity', to: 'pages#disabled_entity'

    resources :users, concerns: :history do
      collection do
        get :export_all
        get :export_selected
        get :select2_remote
        post :profile_picture
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
      resources :synchronizations, only: [:index, :create] do
        collection do
          get :current_syncronization_data
        end
      end
    end
    resource :general_configurations, only: [:edit, :update], concerns: :history
    resource :entity_configurations, only: [:edit, :update], concerns: :history
    resource :terms_dictionaries, only: [:edit, :update], concerns: :history
    resources :admin_synchronizations, only: [:index]
    resources :backup_files, only: [:index, :create]
    resources :unities, concerns: :history do
      collection do
        delete :destroy_batch
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
      get :grades_by_unities, on: :collection
    end
    resources :test_setting_tests, only: [:index, :show]

    resources :school_calendar_event_batches
    resources :school_calendars, concerns: :history do
      collection do
        get :step
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
    resources :learning_objectives_and_skills, concerns: :history do
      collection do
        get :contents
      end
    end

    get '/pedagogical_trackings', as: :pedagogical_trackings, to: 'pedagogical_trackings#index'
    get '/pedagogical_trackings_teachers', as: :pedagogical_trackings_teachers, to: 'pedagogical_trackings#teachers'
    get '/translations', as: :translations, to: 'translations#form'
    post '/translations', as: :save_translations, to: 'translations#save'
    resources :discipline_lesson_plans, concerns: :history do
      collection do
        post :clone
        get :teaching_plan_contents
        get :teaching_plan_objectives
      end
    end
    resources :knowledge_area_lesson_plans, concerns: :history do
      collection do
        post :clone
        get :teaching_plan_contents
        get :teaching_plan_objectives
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
        get :search_grouped_by_knowledge_area
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
        put :create_or_update_multiple
        delete :destroy_multiple
      end
    end
    get 'daily_frequency/history_multiple', to: 'daily_frequencies#history_multiple', as: 'history_multiple_daily_frequency'

    resources :absence_justifications, concerns: :history
    resources :observation_diary_records, except: :show, concerns: :history
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

    resources :infrequency_trackings, only: :index

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
    get '/reports/partial_score_record/students_by_daily_note', to: 'partial_score_record_report#students_by_daily_note', as: 'students_by_daily_note'
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
end
