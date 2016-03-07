class ConceptualExamPoster
  def self.post!(posting)
    new(posting).post!
  end

  def initialize(posting)
    self.posting = posting
  end

  def post!
    post_conceptual_exams.each do |classroom_id, conceptual_exam_classroom|
      conceptual_exam_classroom.each do |discipline_id, conceptual_exam_discipline|
        api.send_post( notas: { classroom_id => { discipline_id => conceptual_exam_discipline } }, etapa: posting.school_calendar_step.to_number )
      end
    end

  end

  private

  attr_accessor :posting

  def api
    IeducarApi::PostExams.new(posting.to_api)
  end

  def post_conceptual_exams
    params = Hash.new{ |h, k| h[k] = Hash.new(&h.default_proc) }

    conceptual_exams = ConceptualExam.by_teacher(posting.author.teacher)
      .by_unity(posting.school_calendar_step.school_calendar.unity)
      .by_school_calendar_step(posting.school_calendar_step)

    conceptual_exams.each do |conceptual_exam|
      conceptual_exam.conceptual_exam_values.each do |conceptual_exam_value|
        classroom_api_code = conceptual_exam.classroom.api_code
        student_api_code = conceptual_exam.student.api_code
        discipline_api_code = conceptual_exam_value.discipline.api_code
        params[classroom_api_code][student_api_code][discipline_api_code]["valor"] = conceptual_exam_value.value
      end
    end

    params
  end
end
