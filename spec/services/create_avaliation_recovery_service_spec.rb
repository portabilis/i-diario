require 'rails_helper'

RSpec.describe CreateAvaliationRecoveryService do
  let(:teacher) { create(:teacher) }
  let(:avaliation) { create(:avaliation, :with_teacher_discipline_classroom, teacher: teacher, should_create_recovery: true) }
  let(:daily_note) { create(:daily_note, avaliation: avaliation) }
  let(:student) { create(:student) }
  let(:enrollment) { double(student_id: student.id) }
  let(:service) { described_class.new(avaliation, teacher_id: teacher.id, daily_note: daily_note) }

  before do
    allow_any_instance_of(described_class).to receive(:student_enrollments).and_return([enrollment])

    general_config = double(allow_automatic_avaliation_recovery: true)
    allow(GeneralConfiguration).to receive(:current).and_return(general_config)
  end

  describe '#call' do
    context 'when should_create_recovery is true and has students' do
      before do
        create(:daily_note_student, daily_note: daily_note, student: student)
      end

      it 'creates recovery automatically' do
        expect { service.call }.to change(AvaliationRecoveryDiaryRecord, :count).by(1)
      end

      it 'creates recovery_diary_record with same date as avaliation' do
        service.call
        recovery = avaliation.reload.avaliation_recovery_diary_record

        expect(recovery).to be_present
        expect(recovery.recovery_diary_record.recorded_at).to eq(avaliation.test_date)
      end

      it 'creates recovery with same unity, classroom and discipline' do
        service.call
        recovery_record = avaliation.reload.avaliation_recovery_diary_record.recovery_diary_record

        expect(recovery_record.unity).to eq(avaliation.unity)
        expect(recovery_record.classroom).to eq(avaliation.classroom)
        expect(recovery_record.discipline).to eq(avaliation.discipline)
      end

      it 'populates students in recovery' do
        service.call
        recovery_record = avaliation.reload.avaliation_recovery_diary_record.recovery_diary_record

        expect(recovery_record.students.map(&:student_id)).to include(student.id)
      end
    end

    context 'when should_create_recovery is false' do
      let(:avaliation) { create(:avaliation, :with_teacher_discipline_classroom, teacher: teacher, should_create_recovery: false) }

      it 'does not create recovery' do
        create(:daily_note_student, daily_note: daily_note, student: student)

        expect { service.call }.not_to change(AvaliationRecoveryDiaryRecord, :count)
      end
    end

    context 'when there are no daily_note_students' do
      before { daily_note }

      it 'does not create recovery' do
        expect { service.call }.not_to change(AvaliationRecoveryDiaryRecord, :count)
      end
    end

    context 'when recovery already exists' do
      before do
        create(:daily_note_student, daily_note: daily_note, student: student)
        service.call
      end

      it 'does not create another recovery' do
        expect { service.call }.not_to change(AvaliationRecoveryDiaryRecord, :count)
      end
    end

    context 'when daily_note does not exist' do
      let(:service) { described_class.new(avaliation, teacher_id: teacher.id, daily_note: nil) }

      it 'does not create recovery' do
        expect { service.call }.not_to change(AvaliationRecoveryDiaryRecord, :count)
      end
    end

    context 'when allow_automatic_avaliation_recovery is disabled' do
      before do
        create(:daily_note_student, daily_note: daily_note, student: student)

        general_config = double(allow_automatic_avaliation_recovery: false)
        allow(GeneralConfiguration).to receive(:current).and_return(general_config)
      end

      it 'does not create recovery' do
        expect { service.call }.not_to change(AvaliationRecoveryDiaryRecord, :count)
      end
    end

    context 'when student_enrollments returns empty (e.g. fetch failed)' do
      before do
        create(:daily_note_student, daily_note: daily_note, student: student)
        allow_any_instance_of(described_class).to receive(:student_enrollments).and_return([])
      end

      it 'does not create recovery' do
        expect { service.call }.not_to change(AvaliationRecoveryDiaryRecord, :count)
      end
    end
  end
end
