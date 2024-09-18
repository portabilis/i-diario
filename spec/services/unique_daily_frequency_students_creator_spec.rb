require 'rails_helper'

RSpec.describe UniqueDailyFrequencyStudentsCreator, type: :service do
  Timecop.travel(Time.zone.local(2024, 4, 1, 0, 0, 0))
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
      discipline: discipline,
      teacher: teacher
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

    it 'create a unique_daily_frequency_student record' do
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

    it 'create a UniqueDailyFrequencyStudent record when the teacher has a lesson in the classroom' do
      student_id = daily_frequency.students.first.student_id

      expect(unique_daily_frequency_student_creator).to eq({ student_id => expected_attributes })
    end

    it 'raises ActiveRecord::RecordInvalid when the teacher does not have a lesson in the classroom' do
      teacher_discipline_classroom.destroy
      expect{unique_daily_frequency_student_creator}.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context '#validate_parameters!' do
    it 'create a UniqueDailyFrequencyStudent record when params are correct' do
      subject(:unique_daily_frequency_student_creator) do
        described_class.create!(
          classroom.id,
          daily_frequency.frequency_date,
          teacher.id
        )
      end

      student_id = daily_frequency.students.first.student_id

      expect(unique_daily_frequency_student_creator).to eq({ student_id => expected_attributes })
    end

    it 'return raises ArgumentError when params are nil' do
      expect{
        UniqueDailyFrequencyStudentsCreator.create!(nil, nil, nil)
      }.to raise_error(ArgumentError, /Parâmetros inválidos: classroom_id, frequency_date and teacher_id não estão presentes/)
    end
  end

end
