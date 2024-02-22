require 'rails_helper'

RSpec.describe ExamPoster::NumericalExamPoster do
  let!(:discipline) { create(:discipline) }
  let!(:exam_rule) { create(:exam_rule, recovery_type: RecoveryTypes::PARALLEL) }
  let!(:classroom) {
    create(
      :classroom,
      :with_classroom_semester_steps,
      :with_student_enrollment_classroom_with_date,
      :score_type_numeric_and_concept_create_rule
    )
  }
  let!(:teacher_discipline_classroom) {
    create(
      :teacher_discipline_classroom,
      classroom: classroom,
      discipline: discipline,
      score_type: ScoreTypes::NUMERIC
    )
  }
  let!(:exam_posting) {
    create(
      :ieducar_api_exam_posting,
      school_calendar_classroom_step: classroom.calendar.classroom_steps.first,
      teacher: teacher_discipline_classroom.teacher
    )
  }
  let!(:grade) { create(:grade) }
  let!(:school_calendar_discipline_grade) {
    create(
      :school_calendar_discipline_grade,
      school_calendar: classroom.calendar.school_calendar,
      discipline: discipline,
      grade: grade
    )
  }
  let!(:avaliation) {
    create(
      :avaliation,
      teacher_id: teacher_discipline_classroom.teacher.id,
      classroom: classroom,
      discipline: discipline,
      grade_ids: [grade.id]
    )
  }
  let!(:daily_note) { create(:daily_note, avaliation: avaliation) }
  let!(:daily_note_student) {
    create(
      :daily_note_student,
      student_id: classroom.student_enrollment_classrooms.first.student_id,
      daily_note: daily_note,
      note: 4
    )
  }
  let(:complementary_exam_setting) {
    create(
      :complementary_exam_setting,
      :with_teacher_discipline_classroom,
      grades: [grade],
      calculation_type: CalculationTypes::SUM
    )
  }
  let(:complementary_exam) {
    create(
      :complementary_exam,
      unity: classroom.unity,
      discipline: discipline,
      classroom: classroom,
      complementary_exam_setting: complementary_exam_setting,
      teacher_id: teacher_discipline_classroom.teacher.id
    )
  }
  let(:complementary_exam_student) {
    create(
      :complementary_exam_student,
      complementary_exam: complementary_exam,
      student: daily_note_student.student
    )
  }

  let(:scores) { Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) } }
  let(:request) {
    {
      'etapa' => avaliation.current_step.to_number,
      'resource' => 'notas'
    }
  }
  let(:info) {
    {
      classroom: classroom.api_code,
      student: daily_note_student.student.api_code,
      discipline: teacher_discipline_classroom.discipline.api_code
    }
  }

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
    let(:current_user) { create(:user) }
    let(:recovery_student) { recovery_diary_record.students.first }
    let!(:recovery_diary_record) {
      recovery_diary_record = create(
        :recovery_diary_record,
        :with_teacher_discipline_classroom,
        unity: classroom.unity,
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
      current_user.current_classroom_id = recovery_diary_record.classroom_id
      current_user.current_discipline_id = recovery_diary_record.discipline_id
      allow(recovery_diary_record).to receive(:current_user).and_return(current_user)

      recovery_diary_record
    }
    let!(:school_term_recovery_diary_record) {
      step = StepsFetcher.new(recovery_diary_record.classroom).step_by_date(recovery_diary_record.recorded_at)
      create(
        :school_term_recovery_diary_record,
        recovery_diary_record: recovery_diary_record,
        step_id: step.id,
        step_number: step.step_number
      )
    }
    context 'hasnt complementary exams' do
      it 'queued request score match to recovery score' do
        subject.post!
        scores[classroom.api_code][daily_note_student.student.api_code][avaliation.discipline.api_code]['nota'] = daily_note_student.note.to_f
        scores[classroom.api_code][daily_note_student.student.api_code][avaliation.discipline.api_code]['recuperacao'] = recovery_student.score
        request['notas'] = scores

        expect(Ieducar::SendPostWorker).to have_enqueued_sidekiq_job(
          Entity.first.id,
          exam_posting.id,
          request,
          info,
          "critical",
          0
        )
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

        expect(Ieducar::SendPostWorker).to have_enqueued_sidekiq_job(
          Entity.first.id,
          exam_posting.id,
          request,
          info,
          "critical",
          0
        )
      end
    end

    it 'expects to call score_rounder with correct params' do
      score_rounder = double(:score_rounder)

      expect(ScoreRounder).to receive(:new)
        .with(
          classroom,
          RoundedAvaliations::SCHOOL_TERM_RECOVERY,
          classroom.calendar.classroom_steps.first
        )
        .and_return(score_rounder)
        .at_least(:once)

      expect(ScoreRounder).to receive(:new)
        .with(
          classroom,
          RoundedAvaliations::NUMERICAL_EXAM,
          classroom.calendar.classroom_steps.first
        )
        .and_return(score_rounder)
        .at_least(:once)

      expect(score_rounder).to receive(:round)
        .with(anything)
        .at_least(:once)

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
      scores[classroom.api_code][daily_note_student.student.api_code][avaliation.discipline.api_code]['nota'] =
        daily_note_student.note.to_f
      request['notas'] = scores

      expect(Ieducar::SendPostWorker)
        .not_to have_enqueued_sidekiq_job(Entity.first.id, exam_posting.id, request)
    end
  end
end
