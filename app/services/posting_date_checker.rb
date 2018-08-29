class PostingDateChecker
  def initialize(classroom, record_date)
    @classroom = classroom
    @record_date = record_date
  end

  def check
    return true if User.current.can_change?(Features::IEDUCAR_API_EXAM_POSTING_WITHOUT_RESTRICTIONS)
    return false unless step
    return (step.start_date_for_posting..step.end_date_for_posting) === Date.today
  end

  private

  def step
    @step ||= StepsFetcher.new(@classroom).step(@record_date)
  end
end
