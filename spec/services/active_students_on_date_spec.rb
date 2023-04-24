# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActiveStudentsOnDate, type: :service do
  context '#call' do
    let(:student_enrollment) { create(:student_enrollment) }

    context 'when parameters are correct' do
      it 'should returns enrollment classrooms on date' do
        enrollment_classrooms_on_date = create_list(
          :student_enrollment_classroom,
          3,
          joined_at: '2017-01-01',
          student_enrollment: student_enrollment
        )

        enrollments_hash = ActiveStudentsOnDate.call(student_enrollments: student_enrollment.id, date: '2017-05-05')

        enrollment_classrooms_on_date.each do |enrollment_classroom|
          expect(enrollments_hash).to include(enrollment_classroom.id => ['2017-05-05'])
        end
        expect(enrollments_hash.size).to be(3)
      end

      it 'should not returns enrollment classrooms out of date' do
        enrollment_classrooms_out_date = create_list(
          :student_enrollment_classroom,
          3,
          joined_at: '2017-01-01',
          left_at: '2017-04-04',
          student_enrollment: student_enrollment
        )

        enrollments_hash = ActiveStudentsOnDate.call(student_enrollments: student_enrollment.id, date: '2017-05-05')

        enrollment_classrooms_out_date.each do |enrollment_classroom|
          expect(enrollments_hash).to_not include(enrollment_classroom.id => ['2017-05-05'])
        end
      end
    end

    context 'when parameters are not correct' do
      it 'should return error date parameter missing' do
        expect { ActiveStudentsOnDate.call(student_enrollments: student_enrollment.id) }.to raise_error(KeyError, 'key not found: :date')
      end

      it 'should return empty hash to params student_enrollments invalid' do
        expect(
          ActiveStudentsOnDate.call(
            student_enrollments: '2017-05-05',
            date: '2017-05-05'
          )
        ).to be_empty
      end

      it 'should return invalid date error' do
        expect {
          ActiveStudentsOnDate.call(
            student_enrollments: student_enrollment.id,
            date: student_enrollment.id
          )
        }.to raise_error(NoMethodError)
      end
    end
  end
end
