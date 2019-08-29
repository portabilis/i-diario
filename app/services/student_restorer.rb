class StudentRestorer
  def initialize(main_student, secondary_students)
    @main_student = main_student
    @secondary_students = secondary_students
  end

  def restore!; end

  private

  attr_accessor :error
end
