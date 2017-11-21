class IeducarApiExamPostingsController < ApplicationController
  before_action :require_current_teacher
  before_action :require_current_teacher_discipline_classrooms
   
  before_action :require_current_posting_step

  def index
    classroom_steps.any? ? school_calendar_classroom_steps : school_calendar_steps
  end

  def create
    authorize(IeducarApiExamPosting.new)

    ieducar_api_exam_posting = IeducarApiExamPosting.new(permitted_attributes)
    ieducar_api_exam_posting.author = current_user
    ieducar_api_exam_posting.status = ApiSynchronizationStatus::STARTED
    ieducar_api_exam_posting.ieducar_api_configuration = IeducarApiConfiguration.current

    ieducar_api_exam_posting.save!

    IeducarExamPostingWorker.perform_async(current_entity.id, ieducar_api_exam_posting.id)

    redirect_to ieducar_api_exam_postings_path
  end

  protected

  def permitted_attributes
    params.permit(:school_calendar_step_id,
                  :school_calendar_classroom_step_id,
                  :post_type)
  end

  def school_calendar_steps
    @school_calendar_steps = SchoolCalendarStep.by_school_calendar_id(current_school_calendar.id)
    .ordered

    @school_calendar_steps = @school_calendar_steps.posting_date_after_and_before(Time.zone.today) unless current_user.can_change?("ieducar_api_exam_posting_without_restrictions")

    @school_calendar_steps.each do |step|
      ApiPostingTypes.each_value do |value|
        ieducar_api_exam_posting = IeducarApiExamPosting.where(school_calendar_step: step.id, author_id: current_user.id).send(value).last
        instance_variable_set("@school_calendar_step_#{step.id}_#{value}_posting", ieducar_api_exam_posting)
      end
    end
  end

  def school_calendar_classroom_steps
    @school_calendar_classroom_steps = SchoolCalendarClassroomStep.by_classroom(current_user_classroom)

    @school_calendar_classroom_steps = @school_calendar_classroom_steps.posting_date_after_and_before(Time.zone.today) unless current_user.can_change?("ieducar_api_exam_posting_without_restrictions")

    @school_calendar_classroom_steps.each do |step|
      ApiPostingTypes.each_value do |value|
        ieducar_api_exam_posting = IeducarApiExamPosting.where(school_calendar_classroom_step: step.id, author_id: current_user.id).send(value).last
        instance_variable_set("@school_calendar_classroom_step_#{step.id}_#{value}_posting", ieducar_api_exam_posting)
      end
    end
  end

  def classroom_steps
    @school_calendar_classroom_steps = SchoolCalendarClassroomStep.by_classroom(current_user_classroom)
  end

  def require_current_posting_step
    return unless current_school_calendar

    unless current_user.can_change?("ieducar_api_exam_posting_without_restrictions") || current_school_calendar.posting_step(Time.zone.today)
      flash[:alert] = t('errors.ieducar_api_exam_postings.require_current_posting_step')

      redirect_to root_path
    end
  end
end
