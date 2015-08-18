class IeducarApiExamPostingsController < ApplicationController
  before_action :require_current_teacher
  before_action :require_current_teacher_discipline_classrooms
  before_action :require_current_school_calendar
  before_action :require_current_posting_step

  def index
    ApiPostingTypes.each_value do |value|
      instance_variable_set "@#{value}_posting", IeducarApiExamPosting.where(author_id: current_user.id).send(value).last
    end
  end

  def create
    authorize IeducarApiExamPosting.new
    ieducar_api_exam_posting = IeducarApiExamPosting.new(permitted_attributes)
    ieducar_api_exam_posting.author = current_user
    ieducar_api_exam_posting.school_calendar_step = current_school_calendar.posting_step Date.today
    ieducar_api_exam_posting.status = ApiSyncronizationStatus::STARTED
    ieducar_api_exam_posting.ieducar_api_configuration = IeducarApiConfiguration.current

    ieducar_api_exam_posting.save!

    IeducarExamPostingWorker.perform_async(current_entity.id, ieducar_api_exam_posting.id)

    redirect_to ieducar_api_exam_postings_path
  end

  protected

  def permitted_attributes
    params.permit(:post_type)
  end

  def require_current_posting_step
    return unless current_school_calendar
    unless current_school_calendar.posting_step Date.today
      flash[:alert] = t('errors.ieducar_api_exam_postings.require_current_posting_step')
      redirect_to root_path
    end
  end
end
