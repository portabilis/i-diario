class PostingDateChecker
  def initialize(classroom, record_date)
    @classroom = classroom
    @record_date = record_date
  end

  def check
    return true if thread_origin_type_is_api?
    return true unless User.current
    return true if User.current.can_change?(Features::IEDUCAR_API_EXAM_POSTING_WITHOUT_RESTRICTIONS)
    return false unless step
    return current_between_step? && record_date_between_step?
  end

  private

  def record_date_between_step?
    (step.start_date_for_posting..step.end_date_for_posting) === @record_date
  end

  def current_between_step?
    (step.start_date_for_posting..step.end_date_for_posting) === Date.current
  end

  def step
    @step ||= StepsFetcher.new(@classroom).step_by_date(@record_date)
  end

  def thread_origin_type_is_api?
    OriginTypes::API_V2 == Thread.current[:origin_type]
  end
end
