class ExamRuleFetcher
  def initialize(classroom, student)
    @classroom = classroom
    @student = student
  end

  def self.fetch(classroom, student)
    self.new(classroom, student).fetch
  end

  def fetch
    return nil unless @classroom.exam_rule.present?
    if @student.uses_differentiated_exam_rule
      (@classroom.exam_rule.differentiated_exam_rule || @classroom.exam_rule)
    else
      @classroom.exam_rule
    end
  end
end
