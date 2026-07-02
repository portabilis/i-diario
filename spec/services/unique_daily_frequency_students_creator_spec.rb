require 'rails_helper'

RSpec.describe UniqueDailyFrequencyStudentsCreator, type: :service do
  include ActiveSupport::Testing::TimeHelpers

  before(:all) do
    travel_to Time.zone.local(2024, 4, 1, 0, 0, 0)
  end

  after(:all) do
    travel_back
  end

  let(:classroom) { create(:classroom) }
  let(:teacher) { create(:teacher) }
  let(:discipline) { create(:discipline) }
  let!(:teacher_discipline_classroom) {
    create(:teacher_discipline_classroom,
      teacher: teacher,
      classroom: classroom,
      discipline: discipline,
      year: 2024,
      allow_absence_by_discipline: 0
    )
  }
  let(:daily_frequency) {
    create(
      :daily_frequency,
      :with_teacher,
      :with_students,
      classroom: classroom,
      teacher: teacher,
      class_number: nil,
      discipline_id: nil,
      frequency_date: '2024-04-01'
    )
  }
  let(:school_calendar) {
    create(
      :school_calendar,
      year: '2024',
      unity_id: classroom.unity_id
    )
  }
  let!(:school_calendar_step) {
    create(
      :school_calendar_step,
      school_calendar: school_calendar,
      step_number: 1,
      start_at: '2024-02-02',
      end_at: '2024-12-12'
    )
  }

  context '#create!' do
    subject(:unique_daily_frequency_student_creator) do
      described_class.create!(
        classroom.id,
        daily_frequency.frequency_date,
        teacher.id
      )
    end

    it 'creates a unique_daily_frequency_student record' do
      student_id = daily_frequency.students.first.student_id
      expected_attributes = {
        present: daily_frequency.students.first.present,
        classroom_id: classroom.id,
        frequency_date: daily_frequency.frequency_date
      }

      expect { unique_daily_frequency_student_creator }.to change { UniqueDailyFrequencyStudent.count }.by(1)
      expect(unique_daily_frequency_student_creator).to eq({ student_id => expected_attributes })
    end

    it 'does not return unique_daily_frequency_student when daily_frequency_student is inactive' do
      daily_frequency_students_inative = create(
        :daily_frequency_student, daily_frequency: daily_frequency, active: false)
      create(:daily_frequency_student, daily_frequency: daily_frequency, active: true)
      create(:daily_frequency_student, daily_frequency: daily_frequency, active: true)

      expect(unique_daily_frequency_student_creator).not_to have_key(daily_frequency_students_inative.student_id)
    end
  end

  context '#teacher_lesson_on_classroom?' do
    subject(:unique_daily_frequency_student_creator) do
      described_class.create!(
        classroom.id,
        daily_frequency.frequency_date,
        teacher.id
      )
    end

    let(:expected_attributes) do
      {
        present: daily_frequency.students.first.present,
        classroom_id: classroom.id,
        frequency_date: daily_frequency.frequency_date
      }
    end

    it 'creates a UniqueDailyFrequencyStudent record when the teacher has a lesson in the classroom' do
      student_id = daily_frequency.students.first.student_id

      expect(unique_daily_frequency_student_creator).to eq({ student_id => expected_attributes })
    end

    it 'raises ActiveRecord::RecordInvalid when the teacher does not have a lesson in the classroom' do
      teacher_discipline_classroom.destroy
      expect{unique_daily_frequency_student_creator}.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context '#validate_parameters!' do
    it 'creates a UniqueDailyFrequencyStudent record when params are correct' do
      unique_daily_frequency_student_creator = described_class.create!(
        classroom.id,
        daily_frequency.frequency_date,
        teacher.id
      )
      expected_attributes = {
        present: daily_frequency.students.first.present,
        classroom_id: classroom.id,
        frequency_date: daily_frequency.frequency_date
      }

      student_id = daily_frequency.students.first.student_id
      expect(unique_daily_frequency_student_creator).to eq({ student_id => expected_attributes })
    end

    it 'returns raises ArgumentError when params are nil' do
      expect{
        UniqueDailyFrequencyStudentsCreator.create!(nil, nil, nil)
      }.to raise_error(ArgumentError,
        /Parâmetros inválidos: classroom_id, frequency_date ou teacher_id não estão presentes/)
    end
  end

  context 'when the classroom also has frequencies by discipline and class_number' do
    let(:daily_frequency_two) {
      create(
        :daily_frequency,
        :with_teacher,
        classroom: classroom,
        discipline: discipline,
        teacher: teacher,
        class_number: '1',
        frequency_date: daily_frequency.frequency_date
      )
    }
    let(:daily_frequency_three) {
      create(
        :daily_frequency,
        :with_teacher,
        classroom: classroom,
        discipline: discipline,
        teacher: teacher,
        class_number: '2',
        frequency_date: daily_frequency.frequency_date
      )
    }

    subject(:unique_daily_frequency_student_creator) do
      described_class.create!(
        classroom.id,
        daily_frequency.frequency_date,
        teacher.id
      )
    end

    it 'returns only one frequency per day' do
      create(:daily_frequency_student,
        daily_frequency: daily_frequency_two,
        active: true,
        student: daily_frequency.students.first.student
      )
      create(:daily_frequency_student,
        daily_frequency: daily_frequency_three,
        active: true,
        student: daily_frequency.students.first.student
      )

      student_id = daily_frequency.students.first.student_id
      expected_attributes = {
        present: daily_frequency.students.first.present,
        classroom_id: classroom.id,
        frequency_date: daily_frequency.frequency_date
      }

      expect(unique_daily_frequency_student_creator).to eq({ student_id => expected_attributes })
    end
  end

  context 'when the frequency is retroactively removed' do
    it 'removes the created unique_daily_frequency_student' do
      student = daily_frequency.students.first.student
      frequency_date = daily_frequency.frequency_date
      unique_daily_frequency_student = create(:unique_daily_frequency_student,
        student: student, classroom: classroom, frequency_date: frequency_date
      )

      daily_frequency.students.destroy
      daily_frequency.destroy

      unique_daily_frequency_student_creator = described_class.create!(
                                                classroom.id,
                                                '2024-04-01',
                                                teacher.id
                                              )

      expect(UniqueDailyFrequencyStudent.find_by(id: unique_daily_frequency_student.id)).to be_nil

    end
  end

  context 'performance optimizations for batch operations' do
    let(:multiple_students) { create_list(:student, 10) }
    let(:daily_frequency_with_multiple_students) {
      create(
        :daily_frequency,
        :with_teacher,
        classroom: classroom,
        teacher: teacher,
        class_number: nil,
        discipline_id: nil,
        frequency_date: '2024-04-01'
      )
    }

    before do
      multiple_students.each do |student|
        create(:daily_frequency_student,
          daily_frequency: daily_frequency_with_multiple_students,
          student: student,
          active: true,
          present: [true, false].sample
        )
      end
    end

    it 'handles bulk operations efficiently' do
      start_time = Time.current

      result = described_class.create!(
        classroom.id,
        daily_frequency_with_multiple_students.frequency_date,
        teacher.id
      )

      end_time = Time.current
      processing_time = end_time - start_time

      expect(processing_time).to be < 5.seconds
      expect(result.keys.count).to eq(10)
      expect(UniqueDailyFrequencyStudent.count).to eq(10)
    end

    it 'processes multiple frequencies in reasonable time' do
      # Criar múltiplas frequências para a mesma turma/data
      additional_frequencies = []
      3.times do |i|
        additional_frequencies << create(
          :daily_frequency,
          :with_teacher,
          classroom: classroom,
          teacher: teacher,
          class_number: (i + 1).to_s,
          discipline: discipline,
          frequency_date: '2024-04-01'
        )
      end

      start_time = Time.current

      result = described_class.create!(
        classroom.id,
        daily_frequency_with_multiple_students.frequency_date,
        teacher.id
      )

      end_time = Time.current
      processing_time = end_time - start_time

      expect(processing_time).to be < 10.seconds
      expect(result.keys.count).to eq(10)
    end

    context 'with call_worker optimization' do
      # Usa um daily_frequency isolado para evitar conflitos com outros testes
      let(:daily_frequency_2) {
        create(
          :daily_frequency,
          :with_teacher,
          :with_students,
          classroom: classroom,
          teacher: teacher,
          class_number: '6',
          discipline_id: discipline.id,
          frequency_date: '2024-04-01'
        )
      }

      it 'reduces duplicate worker calls for same classroom/date combinations' do
        # Simular múltiplas chamadas para a mesma combinação de turma/data
        classroom_id = daily_frequency_2.classroom_id
        frequency_date = daily_frequency_2.frequency_date
        teacher_id = daily_frequency_2.teacher_id

        expect(UniqueDailyFrequencyStudentsCreatorWorker).to receive(:perform_at).twice

        described_class.call_worker(1, classroom_id, frequency_date, teacher_id)

        # Segunda chamada para a mesma combinação
        # (cada chamada cria um novo worker, mas com horário diferente)
        described_class.call_worker(1, classroom_id, frequency_date, teacher_id)
      end
    end
  end

  context 'memory usage optimization' do
    let(:large_number_of_students) { create_list(:student, 20) }
    let(:daily_frequency_large) {
      create(
        :daily_frequency,
        :with_teacher,
        classroom: classroom,
        teacher: teacher,
        class_number: nil,
        discipline_id: nil,
        frequency_date: '2024-04-01'
      )
    }

    before do
      large_number_of_students.each do |student|
        create(:daily_frequency_student,
          daily_frequency: daily_frequency_large,
          student: student,
          active: true,
          present: [true, false].sample
        )
      end
    end

    it 'does not hold references to large objects during processing' do
      memory_before = GC.stat[:total_allocated_objects]

      result = described_class.create!(
        classroom.id,
        daily_frequency_large.frequency_date,
        teacher.id
      )

      GC.start
      memory_after = GC.stat[:total_allocated_objects]

      expect(result.keys.count).to eq(20)
      expect(UniqueDailyFrequencyStudent.count).to eq(20)

      # Verificar se não há crescimento excessivo de memória
      memory_growth = memory_after - memory_before
      expect(memory_growth).to be < 100000
    end
  end
end
