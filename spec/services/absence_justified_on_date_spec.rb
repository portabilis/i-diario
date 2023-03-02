# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AbsenceJustifiedOnDate, type: :service do
  context '#call' do
    context 'when parameters are correct' do
      it 'should returns absence justified on date (per day)' do
        absence_justification = create(:absence_justification)
        absence_justifications_student = absence_justification.absence_justifications_students.first
        student = absence_justifications_student.student
        frequency_date = Date.current

        absence_justifications = AbsenceJustifiedOnDate.call(students: [student.id], date: frequency_date)

        expected = {
          student.id => {
            frequency_date => {
              0 => absence_justifications_student.id
            }
          }
        }

        expect(absence_justifications).to include(expected)
      end

      it 'should returns absence justified on date (per class)' do
        absence_justification = create(:absence_justification, class_number: 2)
        absence_justifications_student = absence_justification.absence_justifications_students.first
        student = absence_justifications_student.student
        frequency_date = Date.current

        absence_justifications = AbsenceJustifiedOnDate.call(students: [student.id], date: frequency_date)

        expected = {
          student.id => {
            frequency_date => {
              2 => absence_justifications_student.id
            }
          }
        }

        expect(absence_justifications).to include(expected)
      end
    end
  end
end
