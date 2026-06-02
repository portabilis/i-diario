require 'rails_helper'

# Cobre a hierarquia ExamRule × TeacherDisciplineClassroom.score_type:
# a regra da turma (ExamRule) tem precedência; o vínculo professor-disciplina
# só decide quando a ExamRule permite os dois tipos (NUMERIC_AND_CONCEPT).
RSpec.describe ExamPoster::NumericalExamPoster do
  let(:discipline) { create(:discipline) }
  let(:grade) { create(:grade) }

  def build_scenario(exam_rule_score_type, tdc_score_type)
    exam_rule = create(:exam_rule, score_type: exam_rule_score_type, recovery_type: RecoveryTypes::PARALLEL)

    classroom = create(
      :classroom,
      :with_classroom_semester_steps,
      :with_student_enrollment_classroom_with_date,
      exam_rule: exam_rule
    )
    classroom.classrooms_grades.each { |cg| cg.update_column(:exam_rule_id, exam_rule.id) }

    tdc = create(
      :teacher_discipline_classroom,
      classroom: classroom,
      discipline: discipline,
      grade: grade,
      score_type: tdc_score_type
    )

    create(
      :school_calendar_discipline_grade,
      school_calendar: classroom.calendar.school_calendar,
      discipline: discipline,
      grade: grade
    )

    avaliation = create(
      :avaliation,
      teacher_id: tdc.teacher.id,
      classroom: classroom,
      discipline: discipline,
      grade_ids: [grade.id]
    )

    daily_note = create(:daily_note, avaliation: avaliation)
    daily_note_student = create(
      :daily_note_student,
      student_id: classroom.student_enrollment_classrooms.first.student_id,
      daily_note: daily_note,
      note: 7
    )

    exam_posting = create(
      :ieducar_api_exam_posting,
      school_calendar_classroom_step: classroom.calendar.classroom_steps.first,
      teacher: tdc.teacher
    )

    {
      classroom: classroom,
      teacher_discipline_classroom: tdc,
      avaliation: avaliation,
      daily_note_student: daily_note_student,
      exam_posting: exam_posting
    }
  end

  def expected_score_request(scenario)
    classroom = scenario[:classroom]
    student = scenario[:daily_note_student].student
    discipline_api_code = scenario[:teacher_discipline_classroom].discipline.api_code
    scores = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
    scores[classroom.api_code][student.api_code][discipline_api_code]['nota'] = scenario[:daily_note_student].note.to_f

    {
      'etapa' => scenario[:avaliation].current_step.to_number,
      'resource' => 'notas',
      'notas' => scores
    }
  end

  context 'when ExamRule is NUMERIC and TDC.score_type is CONCEPT' do
    it 'enqueues the request because ExamRule takes precedence over TDC' do
      scenario = build_scenario(ScoreTypes::NUMERIC, ScoreTypes::CONCEPT)

      described_class.new(scenario[:exam_posting], Entity.first.id).post!

      expect(Ieducar::SendPostWorker.jobs.first['args'][2]).to match(expected_score_request(scenario))
    end
  end

  context 'when ExamRule is NUMERIC and TDC.score_type is NUMERIC' do
    it 'enqueues the request' do
      scenario = build_scenario(ScoreTypes::NUMERIC, ScoreTypes::NUMERIC)

      described_class.new(scenario[:exam_posting], Entity.first.id).post!

      expect(Ieducar::SendPostWorker.jobs.first['args'][2]).to match(expected_score_request(scenario))
    end
  end

  context 'when ExamRule is NUMERIC_AND_CONCEPT and TDC.score_type is NUMERIC' do
    it 'enqueues the request' do
      scenario = build_scenario(ScoreTypes::NUMERIC_AND_CONCEPT, ScoreTypes::NUMERIC)

      described_class.new(scenario[:exam_posting], Entity.first.id).post!

      expect(Ieducar::SendPostWorker.jobs.first['args'][2]).to match(expected_score_request(scenario))
    end
  end

  context 'when ExamRule is NUMERIC_AND_CONCEPT and TDC.score_type is CONCEPT' do
    it 'does not enqueue the request because TDC decides when ExamRule is mixed' do
      scenario = build_scenario(ScoreTypes::NUMERIC_AND_CONCEPT, ScoreTypes::CONCEPT)

      described_class.new(scenario[:exam_posting], Entity.first.id).post!

      expect(Ieducar::SendPostWorker.jobs).to be_empty
    end
  end
end
