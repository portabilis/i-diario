require 'rails_helper'

RSpec.describe StudentUnification::ReverterService, type: :service do
  let!(:main_student) { create(:student) }
  let!(:secondary_student) { create(:student) }
  let(:service) { described_class.new(main_student, [secondary_student]) }

  describe '#unified?' do
    let!(:daily_note_student) do
      create(:daily_note_student, student: main_student)
    end

    context 'when record has an update audit changing student_id from secondary to main' do
      before do
        daily_note_student.audits.create!(
          action: 'update',
          audited_changes: { 'student_id' => [secondary_student.id, main_student.id] }
        )
      end

      it 'returns true' do
        expect(service.send(:unified?, daily_note_student, secondary_student.id)).to be true
      end
    end

    context 'when record has no update audits at all' do
      it 'returns false' do
        expect(service.send(:unified?, daily_note_student, secondary_student.id)).to be false
      end
    end

    context 'when record has update audits but none changing student_id' do
      before do
        daily_note_student.audits.create!(
          action: 'update',
          audited_changes: { 'note' => [5.0, 7.0] }
        )
      end

      it 'returns false' do
        expect(service.send(:unified?, daily_note_student, secondary_student.id)).to be false
      end
    end

    context 'when record has an update audit changing student_id but to a different target' do
      let!(:other_student) { create(:student) }

      before do
        daily_note_student.audits.create!(
          action: 'update',
          audited_changes: { 'student_id' => [other_student.id, main_student.id] }
        )
      end

      it 'returns false' do
        expect(service.send(:unified?, daily_note_student, secondary_student.id)).to be false
      end
    end

    context 'when record has multiple update audits and only one matches' do
      before do
        daily_note_student.audits.create!(
          action: 'update',
          audited_changes: { 'note' => [5.0, 7.0] }
        )
        daily_note_student.audits.create!(
          action: 'update',
          audited_changes: { 'student_id' => [secondary_student.id, main_student.id] }
        )
        daily_note_student.audits.create!(
          action: 'update',
          audited_changes: { 'note' => [7.0, 8.0] }
        )
      end

      it 'returns true' do
        expect(service.send(:unified?, daily_note_student, secondary_student.id)).to be true
      end
    end

    context 'when record has a create audit with student_id (should be ignored)' do
      before do
        daily_note_student.audits.create!(
          action: 'create',
          audited_changes: { 'student_id' => main_student.id }
        )
      end

      it 'returns false' do
        expect(service.send(:unified?, daily_note_student, secondary_student.id)).to be false
      end
    end
  end
end
