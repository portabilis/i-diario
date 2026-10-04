require 'rails_helper'

RSpec.describe TransferNoteCreator, type: :service do
  let(:entity) { Entity.find_by(domain: 'test.host') }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  # test_setting padrão é aritmético com maximum_score 10 => nota máxima permitida 10.0
  let(:daily_note) { create(:daily_note) }
  let(:student) { create(:student) }
  let(:transfer_note) { build(:transfer_note, :with_teacher_discipline_classroom) }

  before do
    # a factory adiciona uma nota automaticamente; limpa para isolar o cenário do teste
    transfer_note.daily_note_students = []
  end

  def attributes_for_note(note)
    ActionController::Parameters.new(
      '0' => {
        daily_note_id: daily_note.id.to_s,
        student_id: student.id.to_s,
        note: note,
        active: 'true'
      }
    ).permit!
  end

  describe '#save' do
    context 'when a note exceeds the avaliation maximum score' do
      subject(:saver) { described_class.new(transfer_note, attributes_for_note('11')) }

      it 'returns false and persists nothing (avoids orphan record)' do
        result = nil
        expect { result = saver.save }.to_not change { [TransferNote.count, DailyNoteStudent.count] }

        expect(result).to eq(false)
        expect(transfer_note).to_not be_persisted
      end

      it 'adds a numericality error on the invalid note' do
        saver.save

        expect(saver.daily_note_students.first.errors.details[:note]).to include(
          a_hash_including(error: :less_than_or_equal_to)
        )
      end
    end

    context 'when no note is informed' do
      subject(:saver) { described_class.new(transfer_note, attributes_for_note('')) }

      it 'returns false and persists nothing' do
        result = nil
        expect { result = saver.save }.to_not change { [TransferNote.count, DailyNoteStudent.count] }

        expect(result).to eq(false)
      end

      it 'adds an at_least_one_note_required error on base' do
        saver.save

        expect(transfer_note.errors.details[:base]).to include(
          a_hash_including(error: :at_least_one_note_required)
        )
      end
    end

    context 'when all notes are within the maximum score' do
      subject(:saver) { described_class.new(transfer_note, attributes_for_note('8')) }

      it 'persists the transfer note with the student notes' do
        expect(saver.save).to eq(true)

        student_note = saver.daily_note_students.first

        expect(transfer_note).to be_persisted
        expect(student_note).to be_persisted
        expect(student_note.transfer_note_id).to eq(transfer_note.id)
        expect(student_note.reload.note.to_f).to eq(8.0)
        expect(student_note.active).to eq(true)
        expect(student_note.discarded_at).to be_nil
      end
    end
  end

  describe 'building the daily note students' do
    it 'parses the localized note (comma decimal)' do
      saver = described_class.new(transfer_note, attributes_for_note('8,00'))

      expect(saver.daily_note_students.length).to eq(1)
      expect(saver.daily_note_students.first.attributes['note'].to_f).to eq(8.0)
    end

    it 'reuses an existing DailyNoteStudent for the same daily_note and student' do
      existing = create(:daily_note_student, daily_note: daily_note, student: student, note: 3)

      saver = described_class.new(transfer_note, attributes_for_note('9,00'))

      expect(saver.daily_note_students.map(&:id)).to eq([existing.id])
      expect(saver.daily_note_students.first.attributes['note'].to_f).to eq(9.0)
    end
  end
end
