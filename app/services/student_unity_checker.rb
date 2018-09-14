class StudentUnityChecker
  def initialize(student, unity)
    raise ArgumentError unless student && unity

    @student = student
    @unity = unity
  end

  def present?
    results = get_student_registrations @student.api_code
    results.any?{|record| record["ano"] == Date.current.year.to_s &&
                          record["codigo_situacao"] == "3" &&
                          record["escola_id"] == @unity.api_code }
  end

  private

  def get_student_registrations(student_api_code)
    IeducarApi::StudentRegistrations.new(IeducarApiConfiguration.current.to_api).fetch(aluno_id: student_api_code)['matriculas']
  end
end
