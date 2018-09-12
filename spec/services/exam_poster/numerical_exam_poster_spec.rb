require 'rails_helper'

RSpec.describe ExamPoster::NumericalExamPoster do
  let!(:exam_posting) do
    create(:ieducar_api_exam_posting,
           school_calendar_step: avaliation.current_step,
           teacher: teacher_discipline_classroom.teacher)
  end
  let!(:daily_note_student) { create(:daily_note_student, daily_note: daily_note, note: 4) }
  let!(:daily_note) { create(:current_daily_note, avaliation: avaliation) }
  let!(:avaliation) { create(:current_avaliation, classroom: classroom, school_calendar: school_calendar) }
  let!(:classroom) { create(:classroom_numeric, unity: unity, exam_rule: exam_rule) }
  let!(:exam_rule) { create(:exam_rule, recovery_type: RecoveryTypes::PARALLEL) }
  let!(:test_setting) { create(:test_setting, year: school_calendar.year) }
  let!(:school_calendar) { create(:current_school_calendar_with_one_step, unity: unity) }
  let!(:unity) { create(:unity) }
  let!(:teacher_discipline_classroom) do
    create(:teacher_discipline_classroom,
           classroom: classroom,
           discipline: avaliation.discipline,
           score_type: DisciplineScoreTypes::NUMERIC)
  end

  let(:complementary_exam_setting) {
    create(
      :complementary_exam_setting,
      grades: [classroom.grade],
      calculation_type: CalculationTypes::SUM
    )
  }
  let(:complementary_exam) {
    create(
      :complementary_exam,
      unity: unity,
      discipline: avaliation.discipline,
      classroom: classroom,
      recorded_at: school_calendar.steps.first.school_day_dates[0],
      step_id: school_calendar.steps.first.id,
      complementary_exam_setting: complementary_exam_setting
    )
  }
  let(:complementary_exam_student) {
    create(
      :complementary_exam_student,
      complementary_exam: complementary_exam,
      student: daily_note_student.student
    )
  }

  let(:scores) { Hash.new{ |hash, key| hash[key] = Hash.new(&hash.default_proc) } }
  let(:request) do
    {
      'etapa' => avaliation.current_step.to_number,
      'resource' => 'notas',
    }
  end

  subject { described_class.new(exam_posting, Entity.first.id) }

  context 'hasnt recovery' do
    context 'hasnt complementary exams' do
      it 'queued request score match to daily note student score' do
        subject.post!
        scores[classroom.api_code][daily_note_student.student.api_code][avaliation.discipline.api_code]['nota'] = daily_note_student.note.to_f
        request['notas'] = scores
        expect(
          Ieducar::SendPostWorker.jobs.first["args"][2]
        ).to match(request)
      end
    end

    context 'has complementary exams for student' do
      before do
        complementary_exam_student.complementary_exam.complementary_exam_setting.update_attribute(:affected_score, AffectedScoreTypes::STEP_AVERAGE)
      end

      it 'change score of queued request' do
        subject.post!
        scores[classroom.api_code][daily_note_student.student.api_code][avaliation.discipline.api_code]['nota'] = (daily_note_student.note + complementary_exam_student.score).to_f
        request['notas'] = scores
        expect(
          Ieducar::SendPostWorker.jobs.first["args"][2]
        ).to match(request)
      end
    end
  end


  context 'has recovery' do
    let(:recovery_student) { recovery_diary_record.students.first }
    let!(:recovery_diary_record) {
      create(
        :current_recovery_diary_record,
        unity: unity,
        classroom: classroom,
        discipline: avaliation.discipline,
        students: [
          build(
            :recovery_diary_record_student,
            recovery_diary_record: nil,
            student: daily_note_student.student,
            score: 8
          )
        ]
      )
    }
    let!(:school_term_recovery_diary_record) {
      create(
        :current_school_term_recovery_diary_record,
        recovery_diary_record: recovery_diary_record,
        step_id: StepsFetcher.new(recovery_diary_record.classroom).step(recovery_diary_record.recorded_at).id
      )
    }
    context 'hasnt complementary exams' do
      it 'queued request score match to recovery score' do
        subject.post!
        scores[classroom.api_code][daily_note_student.student.api_code][avaliation.discipline.api_code]['nota'] = daily_note_student.note.to_f
        scores[classroom.api_code][daily_note_student.student.api_code][avaliation.discipline.api_code]['recuperacao'] = recovery_student.score
        request['notas'] = scores
        expect(
          Ieducar::SendPostWorker.jobs.first["args"][2]
        ).to match(request)
      end
    end

    context 'has complementary exams for student' do
      before do
        complementary_exam_student.complementary_exam.complementary_exam_setting.update_attribute(:affected_score, AffectedScoreTypes::STEP_RECOVERY_SCORE)
      end

      it 'change score of queued request' do
        subject.post!
        scores[classroom.api_code][daily_note_student.student.api_code][avaliation.discipline.api_code]['nota'] = daily_note_student.note.to_f
        scores[classroom.api_code][daily_note_student.student.api_code][avaliation.discipline.api_code]['recuperacao'] = recovery_student.score + complementary_exam_student.score
        request['notas'] = scores
        expect(
          Ieducar::SendPostWorker.jobs.first["args"][2]
        ).to match(request)
      end
    end
  end
end
