# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AbsenceJustifiedOnDate, type: :service do
  context '#call' do
    let(:absence_justification) { create(:absence_justification) }

    context 'when parameters are correct' do
      it 'should returns absence justified on date' do
        absence_justifications_student = absence_justification.absence_justifications_students.first
        student = absence_justifications_student.student
        frequency_date = Date.current

        absence_justifications = AbsenceJustifiedOnDate.call(students: [student.id], date: frequency_date)

        expected = {
          student.id => {
            frequency_date => absence_justifications_student.id
          }
        }

        expect(absence_justifications).to include(expected)
      end
    end
  end
end
