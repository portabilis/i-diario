require 'rails_helper'

RSpec.describe ExamPoster::AbsencePoster do
  let(:teacher) { create(:teacher) }
  let!(:classroom) do
    create(
      :classroom,
      :with_classroom_semester_steps,
      :score_type_numeric,
      period: Periods::MATUTINAL
    )
  end
  let!(:teacher_discipline_classroom) do
    create(:teacher_discipline_classroom, classroom: classroom, teacher: teacher)
  end
  let(:step) { classroom.calendar.classroom_steps.first }
  let(:student) { create(:student) }
  let!(:daily_frequency) do
    create(
      :daily_frequency,
      :without_discipline,
      classroom: classroom,
      unity: classroom.unity,
      frequency_date: step.start_at + 1.day
    )
  end
  let!(:daily_frequency_student) do
    create(
      :daily_frequency_student,
      daily_frequency: daily_frequency,
      student: student,
      present: false
    )
  end
  let(:exam_posting) do
    create(
      :ieducar_api_exam_posting,
      post_type: ApiPostingTypes::ABSENCE,
      school_calendar_classroom_step: step,
      teacher: teacher
    )
  end

  subject { described_class.new(exam_posting, Entity.first.id) }

  describe '#post!' do
    it 'enqueues one flat request per student for the general absence endpoint' do
      subject.post!

      expect(Ieducar::SendPostWorker).to have_enqueued_sidekiq_job(
        Entity.first.id,
        exam_posting.id,
        {
          etapa: step.to_number,
          turma_id: classroom.api_code,
          aluno_id: student.api_code,
          faltas: 1
        },
        {
          classroom: classroom.api_code,
          student: student.api_code
        },
        'critical',
        0
      )
    end

    it 'sends zero when the student has no absences in the step' do
      daily_frequency_student.update!(present: true)

      subject.post!

      expect(Ieducar::SendPostWorker).to have_enqueued_sidekiq_job(
        Entity.first.id,
        exam_posting.id,
        {
          etapa: step.to_number,
          turma_id: classroom.api_code,
          aluno_id: student.api_code,
          faltas: 0
        },
        {
          classroom: classroom.api_code,
          student: student.api_code
        },
        'critical',
        0
      )
    end
  end
end
