require 'rails_helper'

RSpec.describe ExamPoster::AbsencePoster, type: :service do
  let(:teacher) { create(:teacher) }

  subject { described_class.new(exam_posting, entity.id) }

  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:exam_posting) do
    create(
      :ieducar_api_exam_posting,
      post_type: ApiPostingTypes::ABSENCE,
      school_calendar_classroom_step: step,
      teacher: teacher
    )
  end
  let(:step) { classroom.calendar.classroom_steps.first }

  describe '#post! with general frequency' do
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
    let(:absent_student) { create(:student) }
    let(:present_student) { create(:student) }
    let!(:daily_frequencies) do
      (1..3).map do |day|
        create(
          :daily_frequency,
          :without_discipline,
          classroom: classroom,
          unity: classroom.unity,
          frequency_date: step.start_at + day.days
        )
      end
    end

    before do
      # Um aluno com três faltas e outro com uma: contagens diferentes provam que cada requisição
      # carrega o aluno e o valor corretos, e não o último do laço repetido.
      daily_frequencies.each do |daily_frequency|
        create(
          :daily_frequency_student,
          daily_frequency: daily_frequency,
          student: absent_student,
          present: false
        )
      end

      create(
        :daily_frequency_student,
        daily_frequency: daily_frequencies.first,
        student: present_student,
        present: false
      )
      daily_frequencies.drop(1).each do |daily_frequency|
        create(
          :daily_frequency_student,
          daily_frequency: daily_frequency,
          student: present_student,
          present: true
        )
      end
    end

    it 'builds one flat request per student, each with its own absence count' do
      subject.post!

      expect(subject.requests).to match_array(
        [
          {
            info: { classroom: classroom.api_code, student: absent_student.api_code },
            request: {
              etapa: step.to_number,
              turma_id: classroom.api_code,
              aluno_id: absent_student.api_code,
              faltas: 3
            }
          },
          {
            info: { classroom: classroom.api_code, student: present_student.api_code },
            request: {
              etapa: step.to_number,
              turma_id: classroom.api_code,
              aluno_id: present_student.api_code,
              faltas: 1
            }
          }
        ]
      )
    end

    it 'enqueues exactly one job per student and records the batch size' do
      subject.post!

      expect(Ieducar::SendPostWorker.jobs.size).to eq(2)
      expect(exam_posting.worker_batch.reload.total_workers).to eq(2)
    end

    it 'enqueues the request with the arguments the worker expects' do
      subject.post!

      expect(Ieducar::SendPostWorker).to have_enqueued_sidekiq_job(
        entity.id,
        exam_posting.id,
        {
          etapa: step.to_number,
          turma_id: classroom.api_code,
          aluno_id: absent_student.api_code,
          faltas: 3
        },
        {
          classroom: classroom.api_code,
          student: absent_student.api_code
        },
        'critical',
        0
      )
    end

    it 'sends zero when the student has no absences in the step' do
      DailyFrequencyStudent.update_all(present: true)

      subject.post!

      expect(subject.requests.map { |request| request[:request][:faltas] }).to eq([0, 0])
    end

    context 'when the teacher has another classroom in the same calendar' do
      let!(:other_classroom) do
        create(
          :classroom,
          :with_classroom_semester_steps,
          :score_type_numeric,
          unity: classroom.unity,
          school_calendar: classroom.calendar.school_calendar,
          period: Periods::MATUTINAL
        )
      end
      let(:other_student) { create(:student) }

      before do
        create(:teacher_discipline_classroom, classroom: other_classroom, teacher: teacher)

        other_daily_frequency = create(
          :daily_frequency,
          :without_discipline,
          classroom: other_classroom,
          unity: other_classroom.unity,
          frequency_date: step.start_at + 1.day
        )
        create(:daily_frequency_student, daily_frequency: other_daily_frequency, student: other_student, present: false)
      end

      def requested_classrooms
        subject.requests.map { |request| request[:info][:classroom] }.uniq
      end

      it 'sends every classroom of the teacher when the posting has no classroom' do
        subject.post!

        expect(requested_classrooms).to contain_exactly(classroom.api_code, other_classroom.api_code)
      end

      context 'and the posting is restricted to one classroom' do
        let(:exam_posting) do
          create(
            :ieducar_api_exam_posting,
            post_type: ApiPostingTypes::ABSENCE,
            school_calendar_classroom_step: step,
            teacher: teacher,
            classroom: other_classroom,
            automatic: true
          )
        end

        it 'sends only the students of that classroom' do
          subject.post!

          expect(requested_classrooms).to eq([other_classroom.api_code])
          expect(subject.requests.map { |request| request[:info][:student] }).to eq([other_student.api_code])
        end
      end
    end
  end

  describe '#post! with frequency by discipline' do
    let(:discipline) { create(:discipline) }
    let!(:classroom) do
      create(
        :classroom,
        :with_classroom_semester_steps,
        :by_discipline_create_rule,
        period: Periods::MATUTINAL
      )
    end
    let!(:teacher_discipline_classroom) do
      create(
        :teacher_discipline_classroom,
        classroom: classroom,
        discipline: discipline,
        teacher: teacher
      )
    end
    let(:student) { create(:student) }
    let!(:daily_frequency) do
      create(
        :daily_frequency,
        classroom: classroom,
        discipline: discipline,
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

    context 'when the posting is restricted to one classroom' do
      let!(:other_classroom) do
        create(
          :classroom,
          :with_classroom_semester_steps,
          :by_discipline_create_rule,
          unity: classroom.unity,
          school_calendar: classroom.calendar.school_calendar,
          period: Periods::MATUTINAL
        )
      end
      let(:other_student) { create(:student) }
      let(:exam_posting) do
        create(
          :ieducar_api_exam_posting,
          post_type: ApiPostingTypes::ABSENCE,
          school_calendar_classroom_step: step,
          teacher: teacher,
          classroom: other_classroom,
          automatic: true
        )
      end

      before do
        create(:teacher_discipline_classroom, classroom: other_classroom, discipline: discipline, teacher: teacher)

        other_daily_frequency = create(
          :daily_frequency,
          classroom: other_classroom,
          discipline: discipline,
          unity: other_classroom.unity,
          frequency_date: step.start_at + 1.day
        )
        create(
          :daily_frequency_student,
          daily_frequency: other_daily_frequency,
          student: other_student,
          present: false
        )
      end

      it 'sends only the students of the posting classroom' do
        subject.post!

        expect(subject.requests.map { |request| request[:info][:classroom] }.uniq).to eq([other_classroom.api_code])
        expect(subject.requests.map { |request| request[:info][:student] }).to eq([other_student.api_code])
      end
    end

    # Este é o formato do qual o Ieducar::SendPostWorker depende para rotear à API legada: se ele
    # for achatado junto com o das faltas gerais, o envio por componente quebra.
    it 'keeps the nested legacy payload, with resource and without turma_id' do
      subject.post!

      expect(subject.requests).to eq(
        [
          {
            info: {
              classroom: classroom.api_code,
              student: student.api_code,
              discipline: discipline.api_code
            },
            request: {
              etapa: step.to_number,
              resource: 'faltas-por-componente',
              faltas: {
                classroom.api_code => {
                  student.api_code => {
                    discipline.api_code => { 'valor' => 1, 'area_do_conhecimento' => nil }
                  }
                }
              }
            }
          }
        ]
      )
      expect(subject.requests.map { |request| request[:request][:turma_id] }).to eq([nil])
    end
  end
end
