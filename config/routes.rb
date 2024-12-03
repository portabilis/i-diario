require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

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
        get 'list_attendances_by_classroom', to: 'list_attendances_by_classroom#index'
        get 'student_activity', to: 'student_activity#check'
        get 'student_classroom_attendances', to: 'student_classroom_attendances#index'
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
        get :recovery_lowest_note
        get :in_recovery
        get :select2_remote
        get :search_autocomplete
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

    get '/discipline_teaching_plans/:id/copy', as: :copy_discipline_teaching_plans, to: 'discipline_teaching_plans#copy'
    post '/discipline_teaching_plans/:id/copy', as: :copy_discipline_teaching_plans, to: 'discipline_teaching_plans#do_copy'

    resources :knowledge_area_teaching_plans, concerns: :history
    resources :knowledge_area_teaching_plans, concerns: :history

    get '/knowledge_area_teaching_plans/:id/copy', as: :copy_knowledge_area_teaching_plans, to: 'knowledge_area_teaching_plans#copy'
    post '/knowledge_area_teaching_plans/:id/copy', as: :copy_knowledge_area_teaching_plans, to: 'knowledge_area_teaching_plans#do_copy'

    resources :learning_objectives_and_skills, concerns: :history do
      collection do
        get :contents
        get :fetch_grades
      end
    end

    resources :pedagogical_trackings, only: [:index], concerns: :history do
      collection do
        get :teachers
        get :recalculate
      end
    end

    get '/pedagogical_trackings_teachers', as: :pedagogical_trackings_teachers, to: 'pedagogical_trackings#teachers'
    get '/translations', as: :translations, to: 'translations#form'
    post '/translations', as: :save_translations, to: 'translations#save'

    resources :discipline_lesson_plans, concerns: :history do
      collection do
        post :clone
        get :teaching_plan_contents
        get :teaching_plan_objectives
        get :print
      end
    end
    resources :knowledge_area_lesson_plans, concerns: :history do
      collection do
        post :clone
        get :teaching_plan_contents
        get :teaching_plan_objectives
        get :print
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
      collection do
        get :by_unity
        get :multi_grade
        get :classroom_grades
      end
      resources :students, only: [:index]
    end
    resources :contents, only: :index
    resources :disciplines, only: [:index] do
      collection do
        get :search
        get :search_by_grade_and_unity
        get :search_grouped_by_knowledge_area
        get :by_classroom
      end
    end
    resources :knowledge_areas, only: [:index]
    resources :exam_rules, only: [:index] do
      collection do
        get :for_school_term_type_recovery
      end
    end
    resources :avaliations, concerns: :history do
      collection do
        get :search
        get :multiple_classrooms
        get :set_avaliation_setting
        get :set_grades_by_classrooms
        get :set_type_score_for_discipline
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
        get :fetch_classrooms
      end
      member do
        post :exempt_students
        post :undo_exemption
      end
    end
    resources :daily_note_students, only: [:index] do
      collection do
        get :old_notes
        get :dependence
      end
    end
    resources :school_term_recovery_diary_records, concerns: :history do
      collection do
        get :fetch_step
        get :fetch_number_of_decimal_places
      end
    end
    resources :transfer_notes, concerns: :history do
      collection do
        get :current_notes
        get :find_step_number_by_classroom
      end
    end
    resources :final_recovery_diary_records, concerns: :history
    resources :avaliation_recovery_diary_records, concerns: :history
    resources :avaliation_recovery_lowest_notes, concerns: :history do
      collection do
        get :exists_recovery_on_step
        get :recorded_at_in_selected_step
        get :fetch_exam_setting_arithmetic
        get :fetch_step
      end
    end
    resources :conceptual_exams, concerns: :history do
      collection do
        get :exempted_disciplines
        get :find_conceptual_exam_by_student
        get :find_step_number_by_classroom
        get :fetch_score_type
      end
    end
    resources :conceptual_exams_in_batchs, concerns: :history do
      collection do
        get :edit_multiple
        get :get_steps
        put :create_or_update_multiple
        delete :destroy_multiple
      end
    end
    resources :old_steps_conceptual_values, except: [:only]
    resources :descriptive_exams, only: [:new, :create, :edit, :show, :update], concerns: :history do
      collection do
        get :find
        get :opinion_types
        get :find_step_number_by_classroom
      end
    end
    resources :daily_frequencies, only: [:new, :create], concerns: :history do
      collection do
        get :edit_multiple
        get :form
        put :create_or_update_multiple
        delete :destroy_multiple
      end
    end

    resources :daily_frequencies_in_batchs, only: [:new, :create], concerns: :history do
      collection do
        get :history_multiple
        get :fetch_frequency_type
        get :fetch_teacher_allocated
        get :form
        put :create_or_update_multiple
        delete :destroy_multiple
      end
    end
    get 'daily_frequency/history_multiple', to: 'daily_frequencies#history_multiple', as: 'history_multiple_daily_frequency'

    resources :absence_justifications, concerns: :history do
      collection do
        get :valid_teacher_period_in_classroom
      end
    end
    resources :observation_diary_records, concerns: :history
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

    resources :lessons_boards do
      collection do
        get :period
        get :number_of_lessons
        get :classrooms_filter
        get :grades_by_unity
        get :teachers_classroom
        get :teachers_classroom_period
        get :not_exists_by_classroom
        get :not_exists_by_classroom_and_period
        get :not_exists_by_classroom_and_grade
        get :teacher_in_other_classroom
        get :classroom_grade
        get :classroom_multi_grade
      end
    end

    get '/reports/attendance_record', to: 'attendance_record_report#form', as: 'attendance_record_report'
    get '/reports/attendance_record/period', to: 'attendance_record_report#period', as: 'period_attendance_record_report'
    get '/reports/attendance_record/number_of_classes', to: 'attendance_record_report#number_of_classes', as: 'number_of_classes_attendance_record_report'
    post '/reports/attendance_record', to: 'attendance_record_report#report', as: 'attendance_record_report'

    get '/reports/attendance_record_report_by_students',
      to: 'attendance_record_report_by_students#form',
      as: 'attendance_record_report_by_students'
    get '/reports/attendance_record_report_by_students/fetch_period_by_classroom',
      to: 'attendance_record_report_by_students#fetch_period_by_classroom',
      as: 'fetch_period_by_classroom_attendance_record_report_by_students'
    get '/reports/attendance_record_report_by_students/report',
      to: 'attendance_record_report_by_students#report',
      as: 'attendance_record_report_by_students_report'

    get '/reports/absence_justification', to: 'absence_justification_report#form', as: 'absence_justification_report'
    post '/reports/absence_justification', to: 'absence_justification_report#report', as: 'absence_justification_report'

    get '/reports/exam_record', to: 'exam_record_report#form', as: 'exam_record_report'
    get '/reports/fetch_step', to: 'exam_record_report#fetch_step', as: 'fetch_step_exam_record_report'
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
    get '/reports/knowledge_area_lesson_plan/fetch_knowledge_areas', to: 'knowledge_area_lesson_plan_report#fetch_knowledge_areas', as: 'fetch_knowledge_areas_knowledge_area_lesson_plan_report'
    post '/reports/knowledge_area_content_record', to: 'knowledge_area_lesson_plan_report#content_record_report', as: 'knowledge_area_content_record_report'

    get '/reports/teacher_report_cards', to: 'teacher_report_cards#form', as: 'teacher_report_cards'
    get '/reports/teacher_report_cards/set_grades_by_classroom', to: 'teacher_report_cards#set_grades_by_classroom', as: 'grade_teacher_report_cards'
    get '/reports/teacher_report_cards/classrooms_filter', to: 'teacher_report_cards#classrooms_filter', as: 'classrooms_filter_teacher_report_cards'
    post '/reports/teacher_report_cards', to: 'teacher_report_cards#report', as: 'teacher_report_cards'

    resources :data_exportations, only: [:index, :create]
  end
end
