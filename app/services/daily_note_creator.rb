class DailyNoteCreator
  attr_reader :daily_note

  def initialize(params)
    @params = params
  end

  def self.find_or_create(params)
    new(params).find_or_create
  end

  def find_or_create
    @daily_note = DailyNote.find_or_initialize_by(@params)

    if @daily_note.new_record?
      student_enrollments = fetch_student_enrollments || []
      student_ids = student_enrollments.map(&:student_id).uniq
      student_ids.each do |student_id|
        if student = Student.find_by_id(student_id)
          @daily_note.students.build(student_id: student.id, daily_note: @daily_note, active: true)
        end
      end

      @daily_note.save
    else
      true
    end
  end

  private

  def fetch_student_enrollments
    return if @daily_note.avaliation.nil?

    @student_enrollments ||= StudentEnrollmentsList.new(
      classroom: @daily_note.classroom,
      grade: @daily_note.avaliation.grade_ids,
      discipline: @daily_note.discipline,
      date: @daily_note.avaliation.test_date,
      score_type: StudentEnrollmentScoreTypeFilters::NUMERIC,
      search_type: :by_date
    ).student_enrollments
  end
end
