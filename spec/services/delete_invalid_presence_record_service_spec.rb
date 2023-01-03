require 'rails_helper'

RSpec.describe DeleteInvalidPresenceRecordService, type: :service do
  describe '#perform' do
    let!(:classroom) {
      create(
        :classroom,
        :score_type_numeric_and_concept,
        :with_student_enrollment_classroom,
        :with_classroom_semester_steps
      )
    }
    let(:student_enrollment_classroom) { classroom.student_enrollment_classrooms.first }
    let(:student_enrollment) { student_enrollment_classroom.student_enrollment }
    let(:daily_frequency) {
      create(
        :daily_frequency,
        classroom: classroom
      )
    }
    let!(:daily_frequency_student) {
      create(
        :daily_frequency_student,
        daily_frequency: daily_frequency,
        student_id: student_enrollment.student_id
      )
    }

    subject { DeleteInvalidPresenceRecordService.new(student_enrollment.student_id, classroom.id) }

    context 'when there is only one enrollment of the student on classroom' do
      context 'and has not left it' do
        it 'does not delete the student frequencies' do
          expect { subject.run! }.to_not(change { DailyFrequencyStudent.count })
        end
      end

      context 'and has left it' do
        it 'deletes the student frequencies' do
          student_enrollment_classroom.update_attribute(:left_at, Date.current - 1)

          expect { subject.run! }.to change { DailyFrequencyStudent.count }.from(1).to(0)
        end
      end
    end

    context 'when there are others enrollments of the student on classroom' do
      let!(:student_enrollment_classroom2) {
        create(
          :student_enrollment_classroom,
          classrooms_grade: classroom.classrooms_grades.first,
          student_enrollment: student_enrollment
        )
      }
      let!(:student_enrollment_classroom3) {
        create(
          :student_enrollment_classroom,
          classrooms_grade: classroom.classrooms_grades.first,
          student_enrollment: student_enrollment
        )
      }

      context 'and one enrollment has left it' do
        it 'does not delete the student frequencies in date after joined date' do
          student_enrollment_classroom.update_attribute(:left_at, Date.current - 1)

          expect { subject.run! }.to_not(change { DailyFrequencyStudent.count })
        end
      end

      context 'and all enrollments of the student has left it' do
        it 'deletes the student frequencies in date after left date' do
          student_enrollment_classroom.update_attribute(:left_at, Date.current - 1)
          student_enrollment_classroom2.update_attribute(:left_at, Date.current - 1)
          student_enrollment_classroom3.update_attribute(:left_at, Date.current - 1)

          expect { subject.run! }.to change { DailyFrequencyStudent.count }.from(1).to(0)
        end
      end
    end
  end
end
