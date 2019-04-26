require 'rails_helper'

RSpec.describe ExamPoster::NumericalExamPoster do
  let!(:daily_note_student) do
    current_daily_note = create(:current_daily_note, avaliation: avaliation)
    create(:daily_note_student, daily_note: current_daily_note, note: 4.0)
  end
  let!(:unity) { create(:unity) }
  let!(:school_calendar) { create(:current_school_calendar_with_one_step, unity: unity) }
  let!(:avaliation) { create(:current_avaliation, classroom: classroom, school_calendar: school_calendar) }
  let!(:classroom) do
    exam_rule = create(:exam_rule, recovery_type: RecoveryTypes::PARALLEL)
    create(:classroom_numeric, unity: unity, exam_rule: exam_rule)
  end
  let!(:teacher_discipline_classroom) do
    create(:teacher_discipline_classroom,
           classroom: classroom,
           discipline: avaliation.discipline,
           score_type: DisciplineScoreTypes::NUMERIC)
  end

  let!(:test_setting) { create(:test_setting, year: school_calendar.year) }
  let!(:student_enrollment) { create(:student_enrollment, student: daily_note_student.student) }
  let!(:student_enrollment_classroom) do
    create(:student_enrollment_classroom,
           student_enrollment: student_enrollment,
           classroom: classroom)
  end

  let(:complementary_exam_setting) do
    create(
      :complementary_exam_setting,
      grades: [classroom.grade],
      calculation_type: CalculationTypes::SUM
    )
  end

  let(:complementary_exam) do
    create(
      :complementary_exam,
      unity: unity,
      discipline: avaliation.discipline,
      classroom: classroom,
      recorded_at: school_calendar.steps.first.school_day_dates[0],
      step_id: school_calendar.steps.first.id,
      complementary_exam_setting: complementary_exam_setting
    )
  end

  let(:complementary_exam_student) do
    create(
      :complementary_exam_student,
      complementary_exam: complementary_exam,
      student: daily_note_student.student
    )
  end

  let!(:exam_posting) do
    create(:ieducar_api_exam_posting,
           school_calendar_step: avaliation.current_step,
           teacher: teacher_discipline_classroom.teacher)
  end

  let(:request) do
    {
      'etapa' => avaliation.current_step.to_number,
      'resource' => 'notas'
    }
  end
  let(:info) do
    {
      classroom: classroom.api_code,
      student: daily_note_student.student.api_code,
      discipline: teacher_discipline_classroom.discipline.api_code
    }
  end

  def build_scores_hash(student_average, recovery_score = nil)
    scores = { 'nota' => student_average.to_f }
    scores['recuperacao'] = recovery_score.to_f if recovery_score
    {
      classroom.api_code => {
        daily_note_student.student.api_code => {
          avaliation.discipline.api_code => scores
        }
      }
    }
  end

  subject { described_class.new(exam_posting, Entity.first.id, 'exam_posting_send') }

  context 'has not recovery' do
    context 'has not complementary exams' do
      it 'queued request score match to daily note student score' do
        subject.post!
        request['notas'] = build_scores_hash(daily_note_student.note)

        expect(Ieducar::SendPostWorker.jobs.first['args'][2]).to match(request)
      end
    end

    context 'has complementary exams for student' do
      before do
        complementary_exam_student.complementary_exam
                                  .complementary_exam_setting
                                  .update!(affected_score: AffectedScoreTypes::STEP_AVERAGE)
      end

      it 'change score of queued request' do
        subject.post!
        student_score = daily_note_student.note + complementary_exam_student.score
        request['notas'] = build_scores_hash(student_score)

        expect(Ieducar::SendPostWorker.jobs.first['args'][2]).to match(request)
      end
    end
  end

  context 'has recovery' do
    let(:recovery_student) { recovery_diary_record.students.first }
    let!(:recovery_diary_record) do
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
    end

    let!(:school_term_recovery_diary_record) do
      step = StepsFetcher.new(recovery_diary_record.classroom).step_by_date(recovery_diary_record.recorded_at)
      create(
        :current_school_term_recovery_diary_record,
        recovery_diary_record: recovery_diary_record,
        step_id: step.id,
        step_number: step.step_number
      )
    end

    context 'has not complementary exams' do
      it 'queued request score match to recovery score' do
        subject.post!
        request['notas'] = build_scores_hash(daily_note_student.note, recovery_student.score)

        expect(Ieducar::SendPostWorker)
          .to have_enqueued_sidekiq_job(Entity.first.id, exam_posting.id, request, info)
      end
    end

    context 'has complementary exams for student' do
      before do
        complementary_exam_student.complementary_exam
                                  .complementary_exam_setting
                                  .update!(affected_score: AffectedScoreTypes::STEP_RECOVERY_SCORE)
      end

      it 'change score of queued request' do
        subject.post!
        recovery_score = recovery_student.score + complementary_exam_student.score
        request['notas'] = build_scores_hash(daily_note_student.note, recovery_score)

        expect(Ieducar::SendPostWorker)
          .to have_enqueued_sidekiq_job(Entity.first.id, exam_posting.id, request, info)
      end
    end

    it 'expects to call score_rounder with correct params' do
      score_rounder = double(:score_rounder)

      expect(ScoreRounder).to receive(:new)
        .with(classroom, RoundedAvaliations::SCHOOL_TERM_RECOVERY)
        .and_return(score_rounder)
        .at_least(:once)

      expect(ScoreRounder).to receive(:new)
        .with(classroom, RoundedAvaliations::NUMERICAL_EXAM)
        .and_return(score_rounder)
        .at_least(:once)

      expect(score_rounder).to receive(:round).with(anything).at_least(:once)

      subject.post!
    end
  end

  context 'when discipline is exempted' do
    let!(:specific_step) do
      create(
        :specific_step,
        classroom: classroom,
        discipline: avaliation.discipline,
        used_steps: (avaliation.current_step.to_number + 1)
      )
    end

    it 'does not enqueue the requests' do
      subject.post!
      request['notas'] = build_scores_hash(daily_note_student.note)

      expect(Ieducar::SendPostWorker).not_to have_enqueued_sidekiq_job(Entity.first.id, exam_posting.id, request)
    end
  end
end
