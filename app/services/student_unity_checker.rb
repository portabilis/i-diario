class StudentUnityChecker
  def initialize(student, unity)
    raise ArgumentError unless student && unity

    @student = student
    @unity = unity
  end

  def present?
    results = IeducarApi::StudentRegistrations.new(IeducarApiConfiguration.current.to_api).fetch(aluno_id: @student.api_code)['matriculas']
    results.any?{|record| record["ano"] == Date.today.year.to_s && record["codigo_situacao"] == "3" && record["escola_id"] == @unity.api_code }
  end
end
