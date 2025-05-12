class IeducarApiExamPostingsController < ApplicationController
  before_action :require_current_classroom
  before_action :require_current_teacher
  before_action :require_current_teacher_discipline_classrooms
  before_action :require_current_posting_step

  def index
    steps
  end

  def create
    authorize(IeducarApiExamPosting.new)

    new_permitted_attributes = permitted_attributes.merge!({ author: current_user })
    new_permitted_attributes = new_permitted_attributes.merge!({ teacher: current_user.current_teacher })
    new_permitted_attributes = new_permitted_attributes.merge!({ ieducar_api_configuration: IeducarApiConfiguration.current })
    new_permitted_attributes = new_permitted_attributes.merge!({ status: ApiSynchronizationStatus::STARTED })

    ieducar_api_exam_posting = IeducarApiExamPosting.create!(new_permitted_attributes)

    ieducar_api_exam_posting_last = IeducarApiExamPosting.where(new_permitted_attributes.merge({status: ApiSynchronizationStatus::COMPLETED })).last

    jid = IeducarExamPostingWorker.perform_in(5.seconds, current_entity.id, ieducar_api_exam_posting.id, ieducar_api_exam_posting_last.try(:id), params[:force_posting])

    WorkerBatch.create!(
      main_job_class: 'IeducarExamPostingWorker',
      main_job_id: jid,
      stateable: ieducar_api_exam_posting
    )

    redirect_to ieducar_api_exam_postings_path
  end

  def done_percentage
    posting = IeducarApiExamPosting.find(params[:id])

    render json: { percentage: posting.done_percentage }
  end

  private

  def permitted_attributes
    params.permit(
      :school_calendar_step_id,
      :school_calendar_classroom_step_id,
      :post_type
    )
  end

  def steps_fetcher
    @steps_fetcher ||= StepsFetcher.new(current_user_classroom)
  end

  def steps
    @steps = steps_fetcher.steps
    @steps = @steps.posting_date_after_and_before(Time.zone.today) unless current_user.can_change?('ieducar_api_exam_posting_without_restrictions')

    @steps.each do |step|
      ApiPostingTypes.each_value do |value|
        ieducar_api_exam_posting = IeducarApiExamPosting.where(step_column => step.id, author_id: current_user.id).send(value).last

        instance_variable_set("@step_#{step.id}_#{value}_posting", ieducar_api_exam_posting)
      end
    end
  end

  def step_column
    @step_column ||= steps_fetcher.step_type == StepTypes::CLASSROOM ? :school_calendar_classroom_step_id : :school_calendar_step_id
  end
  helper_method :step_column

  def require_current_posting_step
    return unless current_school_calendar

    unless current_user.can_change?('ieducar_api_exam_posting_without_restrictions') || current_school_calendar.posting_step(Time.zone.today)
      flash[:alert] = t('errors.ieducar_api_exam_postings.require_current_posting_step')

      redirect_to root_path
    end
  end

  def require_current_teacher_discipline_classrooms
    return if current_teacher&.teacher_discipline_classrooms&.any?

    flash[:alert] = t('errors.general.require_current_teacher_discipline_classrooms')

    redirect_to root_path
  end
end
