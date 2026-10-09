require 'rails_helper'

RSpec.describe TeacherUnification::ReverterService, type: :service do
  let!(:main_teacher) { create(:teacher) }
  let!(:secondary_teacher) { create(:teacher) }
  let(:service) { described_class.new(main_teacher, [secondary_teacher]) }
  let(:foreign_key) { :teacher_id }

  describe '#unified?' do
    let!(:daily_note) do
      create(:daily_note)
    end

    context 'when record has an update audit changing teacher_id from secondary to main' do
      before do
        daily_note.audits.create!(
          action: 'update',
          audited_changes: { 'teacher_id' => [secondary_teacher.id, main_teacher.id] }
        )
      end

      it 'returns true' do
        expect(service.send(:unified?, daily_note, foreign_key, secondary_teacher.id)).to be true
      end
    end

    context 'when record has no update audits' do
      it 'returns false' do
        expect(service.send(:unified?, daily_note, foreign_key, secondary_teacher.id)).to be false
      end
    end

    context 'when record has update audits but none changing teacher_id' do
      before do
        daily_note.audits.create!(
          action: 'update',
          audited_changes: { 'observations' => ['foo', 'bar'] }
        )
      end

      it 'returns false' do
        expect(service.send(:unified?, daily_note, foreign_key, secondary_teacher.id)).to be false
      end
    end

    context 'when record has update audits with teacher_id but wrong target' do
      let!(:other_teacher) { create(:teacher) }

      before do
        daily_note.audits.create!(
          action: 'update',
          audited_changes: { 'teacher_id' => [other_teacher.id, main_teacher.id] }
        )
      end

      it 'returns false' do
        expect(service.send(:unified?, daily_note, foreign_key, secondary_teacher.id)).to be false
      end
    end

    context 'when record has multiple update audits and only one matches' do
      before do
        daily_note.audits.create!(
          action: 'update',
          audited_changes: { 'observations' => ['foo', 'bar'] }
        )
        daily_note.audits.create!(
          action: 'update',
          audited_changes: { 'teacher_id' => [secondary_teacher.id, main_teacher.id] }
        )
      end

      it 'returns true' do
        expect(service.send(:unified?, daily_note, foreign_key, secondary_teacher.id)).to be true
      end
    end
  end
end
