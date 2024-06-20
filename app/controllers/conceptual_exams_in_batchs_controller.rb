class ConceptualExamsInBatchsController < ApplicationController
  has_scope :page, default: 1
  has_scope :per, default: 10

  before_action :require_current_classroom
  before_action :require_current_teacher
  before_action :adjusted_period
  before_action :require_allow_to_modify_prev_years, only: [:create, :update, :destroy_multiple]
  before_action :require_specific_teacher
  before_action :set_classroom_and_step, only: [:create, :create_or_update_multiple]

  def index
    step_id = (params[:filter] || []).delete(:by_step)
    status = (params[:filter] || []).delete(:by_status)

    @conceptual_exams = ConceptualExam.joins(:classroom)
                                      .by_unity(current_unity)
                                      .by_classroom(current_user_classroom)
                                      .by_teacher(current_teacher_id)

    @status = conceptual_exams_status(@conceptual_exams)

    @conceptual_exams = apply_scopes(@conceptual_exams)
                          .group('conceptual_exams.classroom_id, conceptual_exams.step_number')
                          .select('conceptual_exams.classroom_id, conceptual_exams.step_number, count(*)')

    if step_id.present?
      @conceptual_exams = @conceptual_exams.by_step_id(current_user_classroom, step_id)
      params[:filter][:by_step] = step_id
    end

    if status.present?
      @conceptual_exams = @conceptual_exams.by_status(current_user_classroom, current_teacher_id, status)
      params[:filter][:by_status] = status
    end

    authorize @conceptual_exams
  end

  def new
    discipline_score_types = (teacher_differentiated_discipline_score_types + teacher_discipline_score_types).uniq
    not_concept_score = discipline_score_types.none? { |discipline_score_type|
      discipline_score_type == ScoreTypes::CONCEPT
    }

    if not_concept_score
      redirect_to(
        conceptual_exams_path,
        alert: I18n.t('conceptual_exams.new.current_discipline_does_not_have_conceptual_exam')
      )
    end

    return if performed?

    @conceptual_exam = ConceptualExam.new(
      unity_id: current_unity.id,
      classroom_id: current_user_classroom.id,
      recorded_at: Date.current
    ).localized

    authorize @conceptual_exam
  end

  def create
    date_on_step = @steps_fetcher.step_belongs_to_date?(@step.id, resource_params[:recorded_at])
    is_school_day = @step.try(:school_calendar)
                         .school_day?(
                           resource_params[:recorded_at].to_date,
                           nil,
                           resource_params[:classroom_id],
                           resource_params[:discipline_id]
                         )

    unless date_on_step && is_school_day
      flash[:error] = I18n.t('errors.messages.not_school_term_day')

      return redirect_to new_conceptual_exams_in_batch_path
    end

    @recorded_at = resource_params[:recorded_at]
    @conceptual_exams = []
    errors = []

    student_enrollments(@step.start_at, @step.end_at, @classroom).each do |student_enrollment|
      @conceptual_exams << base_service.find_or_initialize_conceptual_exam(
        student_enrollment.student_id,
        resource_params[:recorded_at],
        @classroom,
        current_teacher_id,
        current_user,
        @step
      )
    end

    @conceptual_exams.compact!
    mark_exempted_disciplines

    @conceptual_exam_values = @conceptual_exams.map { |conceptual_exam|
      conceptual_exam.assign_attributes(resource_params) unless conceptual_exam.persisted?

      conceptual_exam_value = conceptual_exam.conceptual_exam_values
                                             .find_or_initialize_by(discipline_id: current_user_discipline.id)

      if !conceptual_exam.persisted? && conceptual_exam_value.invalid?
        errors << conceptual_exam_value.errors
        break
      end

      conceptual_exam_value
    }

    if errors.present? || @conceptual_exams.empty?
      flash[:error] = t('conceptual_exams_in_batchs.messages.create_error')

      redirect_to new_conceptual_exams_in_batch_path
    else
      render :edit_multiple
    end
  end

  def create_or_update_multiple
    conceptual_exams_creator = ConceptualExamsInBatchs::CreateOrUpdateMultiple.new(
      resource_params,
      current_teacher,
      current_user,
      @step
    )

    if conceptual_exams_creator.call!
      flash[:success] = t('conceptual_exams_in_batchs.messages.create_success')

      redirect_to conceptual_exams_in_batchs_path
    else
      flash[:alert] = t('conceptual_exams_in_batchs.messages.create_error')

      redirect_to new_conceptual_exams_in_batch_path
    end
  end

  def destroy_multiple
    conceptual_exams_destroyer = ConceptualExamsInBatchs::DestroyMultiple.new(params)

    if conceptual_exams_destroyer.call!
      flash[:success] = t('conceptual_exams_in_batchs.messages.destroy_success')
    else
      flash[:error] = t('conceptual_exams_in_batchs.messages.destroy_error')
    end

    redirect_to conceptual_exams_in_batchs_path
  end

  def get_steps
    return if params[:classroom_id].blank?

    render json: steps_to_select2(params[:classroom_id])
  end

  private

  def steps_to_select2(classroom_id)
    steps_to_select2 = []
    classroom = Classroom.find(classroom_id)
    steps = steps_fetcher(classroom).steps

    steps.each do |step|
      steps_to_select2 << OpenStruct.new(
        id: step.id,
        name: (step.try(:name) || step.to_s),
        text: (step.try(:text) || step.to_s)
      )
    end

    steps_to_select2
  end

  def resource_params
    params.require(:conceptual_exam).permit(
      :unity_id,
      :classroom_id,
      :recorded_at,
      :student_id,
      :step_id,
      conceptual_exam_values_attributes: [
        :student_id,
        :id,
        :discipline_id,
        :value,
        :exempted_discipline,
        :_destroy
      ]
    )
  end

  def mark_exempted_disciplines
    first_conceptual_exam = @conceptual_exams.first

    return if first_conceptual_exam.recorded_at.blank? || first_conceptual_exam.step.blank?

    @student_enrollments ||= student_enrollments(first_conceptual_exam.step.start_at, first_conceptual_exam.step.end_at, @classroom)

    @conceptual_exams.each do |conceptual_exam|
      next unless (current_student_enrollment = @student_enrollments.find { |item| item[:student_id] == conceptual_exam.student_id })

      exempted_disciplines = current_student_enrollment.exempted_disciplines

      conceptual_exam.conceptual_exam_values.each do |conceptual_exam_value|
        conceptual_exam_value.exempted_discipline = student_exempted_from_discipline?(conceptual_exam_value.discipline_id, exempted_disciplines)
      end
    end
  end

  def steps_fetcher(classroom)
    @steps_fetcher ||= StepsFetcher.new(classroom)
  end

  def student_enrollments(start_at, end_at, classroom)
    step_student_enrollments = "#{start_at}_#{end_at}_student_enrollments_#{classroom}"

    Rails.cache.fetch(step_student_enrollments, expires_in: 10.minutes) do
      StudentEnrollmentsList.new(
        classroom: classroom,
        discipline: current_user_discipline,
        start_at: start_at,
        end_at: end_at,
        score_type: StudentEnrollmentScoreTypeFilters::CONCEPT,
        search_type: :by_date_range,
        period: @period
      ).student_enrollments
    end
  end

  def old_values
    @old_values ||= {}

    @conceptual_exams.each do |conceptual_exam|
      next if conceptual_exam.classroom.nil? && conceptual_exam.student.nil? && conceptual_exam.step.nil?

      @old_values[conceptual_exam.id] ||= OldStepsConceptualValuesFetcher.new(
        conceptual_exam.classroom,
        conceptual_exam.student,
        conceptual_exam.step
      ).fetch
    end

    @old_values.delete_if { |_key, value| value.empty? }
  end
  helper_method :old_values

  def steps_current_classroom
    steps_fetcher(current_user_classroom).steps
  end
  helper_method :steps_current_classroom

  def classrooms_by_current_profile
    Classroom.by_unity_and_teacher(current_unity, current_teacher_id).by_year(current_school_year)
  end
  helper_method :classrooms_by_current_profile

  def student_exempted_from_discipline?(discipline_id, exempted_disciplines)
    exempted_disciplines.by_discipline(discipline_id)
                        .by_step_number(@conceptual_exams.first.step_number)
                        .any?
  end

  def current_teacher_period
    TeacherPeriodFetcher.new(
      current_teacher.id,
      current_user.current_classroom_id,
      current_user.current_discipline_id
    ).teacher_period
  end

  def adjusted_period
    teacher_period = current_teacher_period
    @period = teacher_period != Periods::FULL.to_i ? teacher_period : nil
  end

  def conceptual_exams_status(conceptual_exams)
    steps = steps_fetcher(current_user_classroom).steps
    cache_key = "#{steps.size}-steps-#{current_user_classroom.id}-#{current_teacher.id}"

    Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      status = {}

      steps.each do |step|
        builded_conceptual_exams = []

        student_enrollments(step.start_at, step.end_at, current_user_classroom).each do |student_enrollment|
          builded_conceptual_exams << base_service.find_or_initialize_conceptual_exam(
            student_enrollment.student_id,
            step.end_at,
            current_user_classroom,
            current_teacher_id,
            current_user,
            step
          )
        end

        conceptual_exams_by_step = conceptual_exams.where(step_number: step.step_number)

        next if conceptual_exams_by_step.empty?

        conceptual_exams_by_step.each do |conceptual_exam|
          conceptual_exam_value = conceptual_exam.conceptual_exam_values
                                                 .find_or_initialize_by(discipline_id: current_user_discipline.id)

          status[step.step_number] ||= []

          status[step.step_number] << if conceptual_exam.persisted? && conceptual_exam_value.value.present?
                                        true
                                      else
                                        false
                                      end
        end

        total_persisted_exams = conceptual_exams_by_step.size
        total_builded_exams = builded_conceptual_exams.compact.size

        if (total_builded_exams > total_persisted_exams && total_persisted_exams != total_builded_exams) ||
           status[step.step_number].include?(false)
          status[step.step_number] = ConceptualExamStatus::INCOMPLETE
        else
          status[step.step_number] = ConceptualExamStatus::COMPLETE
        end
      end

      status
    end
  end

  def require_specific_teacher
    return unless current_teacher_discipline_classroom.allow_absence_by_discipline.zero?

    flash[:alert] = t('errors.general.require_specific_teacher')

    redirect_to root_path
  end

  def current_teacher_discipline_classroom
    cache_key = "#{current_user_classroom.id}_#{current_teacher.id}"

    Rails.cache.fetch(cache_key, expires_in: 30.minutes) do
      TeacherDisciplineClassroom.by_classroom(current_user_classroom)
                                .by_teacher_id(current_teacher.id)
                                .first
    end
  end

  def base_service
    @base_service ||= ConceptualExamsInBatchs::Base.new
  end

  def set_classroom_and_step
    @classroom = Classroom.find(resource_params[:classroom_id])
    @steps_fetcher = steps_fetcher(@classroom)
    @step = @steps_fetcher.step_by_id(resource_params[:step_id])
  end
end
