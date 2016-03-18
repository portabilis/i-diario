class DescriptiveExamPoster
  def self.post!(posting)
    new(posting).post!
  end

  def initialize(posting)
    self.posting = posting
  end

  def post!
    post_by_step.each do |classroom_id, classroom_descriptive_exam|
      classroom_descriptive_exam.each do |student_id, descriptive_exam|
        api.send_post(pareceres: { classroom_id => { student_id => descriptive_exam } }, etapa: posting.school_calendar_step.to_number, resource: 'pareceres-por-etapa-geral')
      end
    end

    post_by_year.each do |classroom_id, classroom_descriptive_exam|
      classroom_descriptive_exam.each do |student_id, descriptive_exam|
        api.send_post(pareceres: { classroom_id => { student_id => descriptive_exam } }, resource: 'pareceres-anual-geral')
      end
    end

    post_by_year_and_discipline.each do |classroom_id, classroom_descriptive_exam|
      classroom_descriptive_exam.each do |student_id, student_descriptive_exam|
        student_descriptive_exam.each do |discipline_id, discipline_descriptive_exam|
          api.send_post(pareceres: { classroom_id => { student_id => { discipline_id => discipline_descriptive_exam } } }, resource: 'pareceres-anual-por-componente')
        end
      end
    end

    post_by_step_and_discipline.each do |classroom_id, classroom_descriptive_exam|
      classroom_descriptive_exam.each do |student_id, student_descriptive_exam|
        student_descriptive_exam.each do |discipline_id, discipline_descriptive_exam|
          api.send_post(pareceres: { classroom_id => { student_id => { discipline_id => discipline_descriptive_exam } } }, etapa: posting.school_calendar_step.to_number, resource: 'pareceres-por-etapa-e-componente')
        end
      end
    end
  end

  protected

  attr_accessor :posting

  def api
    IeducarApi::PostDescriptiveExams.new(posting.to_api)
  end

  def post_by_step
    descriptive_exams = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

    teacher.classrooms.uniq.each do |classroom|
      next if classroom.unity_id != posting.school_calendar_step.school_calendar.unity_id
      next if classroom.exam_rule.opinion_type != OpinionTypes::BY_STEP

      exams = DescriptiveExamStudent.by_classroom_and_step(classroom, posting.school_calendar_step.id)
      exams.each do |exam|
        descriptive_exams[classroom.api_code][exam.student.api_code]["valor"] = exam.value
      end
    end

    descriptive_exams
  end

  def post_by_year
    descriptive_exams = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

    teacher.classrooms.uniq.each do |classroom|
      next if classroom.unity_id != posting.school_calendar_step.school_calendar.unity_id
      next if classroom.exam_rule.opinion_type != OpinionTypes::BY_YEAR

      exams = DescriptiveExamStudent.by_classroom(classroom)
      exams.each do |exam|
        descriptive_exams[classroom.api_code][exam.student.api_code]["valor"] = exam.value
      end
    end

    descriptive_exams
  end

  def post_by_year_and_discipline
    descriptive_exams = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

    teacher.teacher_discipline_classrooms.each do |teacher_discipline_classroom|
      classroom = teacher_discipline_classroom.classroom
      discipline = teacher_discipline_classroom.discipline

      next if classroom.unity_id != posting.school_calendar_step.school_calendar.unity_id
      next if classroom.exam_rule.opinion_type != OpinionTypes::BY_YEAR_AND_DISCIPLINE

      exams = DescriptiveExamStudent.by_classroom_and_discipline(classroom, discipline)
      exams.each do |exam|
        descriptive_exams[classroom.api_code][exam.student.api_code][discipline.api_code]["valor"] = exam.value
      end
    end

    descriptive_exams
  end

  def post_by_step_and_discipline
    descriptive_exams = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

    teacher.teacher_discipline_classrooms.each do |teacher_discipline_classroom|
      classroom = teacher_discipline_classroom.classroom
      discipline = teacher_discipline_classroom.discipline

      next if classroom.unity_id != posting.school_calendar_step.school_calendar.unity_id
      next if classroom.exam_rule.opinion_type != OpinionTypes::BY_STEP_AND_DISCIPLINE

      exams = DescriptiveExamStudent.by_classroom_discipline_and_step(classroom, discipline, posting.school_calendar_step.id)
      exams.each do |exam|
        descriptive_exams[classroom.api_code][exam.student.api_code][discipline.api_code]["valor"] = exam.value
      end
    end

    descriptive_exams
  end

  private

  def teacher
    posting.author.teacher
  end
end
