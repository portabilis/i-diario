class StudentPartialScoresFetcher
  include I18n::Alchemy

  def initialize(student_id, school_calendar_step_id, classroom_id)
    @student_id = student_id
    @school_calendar_step_id = school_calendar_step_id
    @classroom_id = classroom_id
  end

  def fetch!
    avaliations = Avaliation.by_classroom_id(classroom_id)
                            .by_school_calendar_step(school_calendar_step_id)
                            .ordered
                            .includes(:discipline, :test_setting, :test_setting_test)

    daily_note_students = daily_note_students_by_avaliation_id(avaliations)

    response = []

    avaliations.each do |avaliation|
      score = daily_note_students[avaliation.id].try(:recovered_note)

      response << {
        avaliation: "#{avaliation}",
        date: I18n.l(avaliation.test_date, format: :week_day),
        discipline: "#{avaliation.discipline.to_s.mb_chars.upcase}",
        weight: numeric_parser.localize(MaximumScoreFetcher.new(avaliation).maximum_score),
        score: numeric_parser.localize(score)
      }
    end
    response
  end

  private

  def daily_note_students_by_avaliation_id(avaliations)
    DailyNoteStudent
      .by_student_id(student_id)
      .by_avaliation(avaliations.map(&:id))
      .includes(daily_note: { avaliation: :recovery_diary_record })
      .order(:id)
      .each_with_object({}) { |dns, hash| hash[dns.daily_note.avaliation_id] ||= dns }
  end

  def numeric_parser
    @numeric_parser ||= I18n::Alchemy::NumericParser
  end

  attr_accessor :student_id, :school_calendar_step_id, :classroom_id
end
