require 'rails_helper'

RSpec.describe DailyNoteHelper, type: :helper do
  let(:daily_note_student) { create(:daily_note_student) }

  describe '#do_undo_link' do
    context '#when params are correct and student is not exempted' do
      it 'creates link to exempt' do
        note_student = daily_note_student
        note_student.active = true
        note_student.dependence = false
        note_student.exempted = false
        note_student.exempted_from_discipline = false
        note_student.in_active_search = false
        expect(helper.do_undo_link(note_student, daily_note_student.daily_note)).to include('Dispensar')
      end
    end

    context '#when params are correct and student is exempted' do
      it 'creates link to undo exempt' do
        note_student = daily_note_student
        note_student.active = true
        note_student.dependence = false
        note_student.exempted = true
        note_student.exempted_from_discipline = true
        note_student.in_active_search = false
        expect(helper.do_undo_link(note_student, daily_note_student.daily_note)).to include('Desfazer')
      end
    end

  end
end
