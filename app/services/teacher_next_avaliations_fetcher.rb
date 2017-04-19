class TeacherNextAvaliationsFetcher
  def initialize(params)
    @teacher = params.fetch(:teacher)
    @classroom = params.fetch(:classroom)
    @discipline = params.fetch(:discipline)
  end

  def fetch!
    avaliations.by_teacher(teacher)
               .by_classroom_id(classroom)
               .by_discipline_id(discipline)
               .by_test_date_between(Time.zone.today, Time.zone.today + 1.week)
               .order(:test_date)
  end

  private

  attr_accessor :teacher, :classroom, :discipline

  def avaliations
    Avaliation
  end
end
