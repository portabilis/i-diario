# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AbsenceJustifiedOnDate, type: :service do
  context '#call' do
    context 'when parameters are correct' do
      it 'should returns absence justified on date (per day)' do
        frequency_date = Date.current

        absence_justification = create(:absence_justification, absence_date_end: frequency_date)
        absence_justifications_student = absence_justification.absence_justifications_students.first
        student = absence_justifications_student.student

        absence_justifications = AbsenceJustifiedOnDate.call(
                                                              students: [student.id],
                                                              date: frequency_date,
                                                              end_date: frequency_date,
                                                              classroom: absence_justification.classroom.id,
                                                              period: absence_justification.period
                                                            )

        expected = {
          student.id => {
            frequency_date => {
              0 => absence_justifications_student.id
            }
          }
        }

        expect(expected).to include(absence_justifications)
      end

      it 'should returns absence justified on date (per day) in batch' do
        frequency_date_yesterday = Date.current - 1
        frequency_date = Date.current
        teacher_discipline_classroom = create(:teacher_discipline_classroom, :with_classroom_semester_steps)

        absence_justification = create(
          :absence_justification,
          absence_date: frequency_date,
          absence_date_end: frequency_date,
          teacher_discipline_classroom: teacher_discipline_classroom
        )
        absence_justification_yesterday = create(
          :absence_justification,
          students: absence_justification.students,
          absence_date: frequency_date_yesterday,
          absence_date_end: frequency_date_yesterday,
          teacher_discipline_classroom: teacher_discipline_classroom
        )

        absence_justifications_student = absence_justification.absence_justifications_students.first
        absence_justification_yesterday_student = absence_justification_yesterday.absence_justifications_students.first
        student = absence_justifications_student.student

        absence_justifications = AbsenceJustifiedOnDate.call(
                                                              students: [student.id],
                                                              date: frequency_date_yesterday,
                                                              end_date: frequency_date,
                                                              classroom: absence_justification.classroom.id,
                                                              period: absence_justification.period
                                                            )

        expected = {
          student.id => {
            frequency_date_yesterday => {
              0 => absence_justification_yesterday_student.id
            },
            frequency_date => {
              0 => absence_justifications_student.id
            }
          }
        }

        expect(expected).to include(absence_justifications)
      end

      it 'should returns absence justified on date (per class)' do
        frequency_date = Date.current

        absence_justification = create(:absence_justification, absence_date_end: frequency_date, class_number: 2)
        absence_justifications_student = absence_justification.absence_justifications_students.first
        student = absence_justifications_student.student

        absence_justifications = AbsenceJustifiedOnDate.call(
                                                              students: [student.id],
                                                              date: frequency_date,
                                                              end_date: frequency_date,
                                                              classroom: absence_justification.classroom.id,
                                                              period: absence_justification.period
                                                            )

        expected = {
          student.id => {
            frequency_date => {
              2 => absence_justifications_student.id
            }
          }
        }

        expect(expected).to include(absence_justifications)
      end
    end
  end
end
