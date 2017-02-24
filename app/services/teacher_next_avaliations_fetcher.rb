class TeacherNextAvaliationsFetcher
  def initialize(teacher)
    @teacher = teacher
  end

  def fetch!
    avaliations.by_teacher(teacher)
               .by_test_date_between(Time.zone.today, Time.zone.today + 1.week)
               .order(:test_date)
  end

  private

  attr_accessor :teacher

  def avaliations
    Avaliation
  end
end
