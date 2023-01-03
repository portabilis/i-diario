# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ActiveStudentsOnDate, type: :service do
  context '#call' do
    let(:student_enrollment) { create(:student_enrollment) }
    let(:enrollment_classrooms_on_date) {
      create_list(
        :student_enrollment_classroom,
        3,
        joined_at: '2017-01-01',
        student_enrollment: student_enrollment
      )
    }
    let(:enrollment_classrooms_out_date) {
      create_list(
        :student_enrollment_classroom,
        3,
        joined_at: '2017-01-01',
        left_at: '2017-04-04',
        student_enrollment: student_enrollment
      )
    }

    subject do
      ActiveStudentsOnDate.call(
        student_enrollments: student_enrollment.id,
        date: '2017-05-05'
      )
    end

    before do
      enrollment_classrooms_on_date
      enrollment_classrooms_out_date
    end

    it 'should returns enrollment classrooms on date' do
      students = subject
      enrollment_classrooms_on_date.each do |enrollment_classroom|
        expect(students).to include({ enrollment_classroom.id => ['2017-05-05'] })
      end
      expect(subject.size).to be(3)
    end

    it 'should not returns enrollment classrooms out of date' do
      students = subject
      enrollment_classrooms_out_date.each do |enrollment_classroom|
        expect(students).to_not include({ enrollment_classroom.id => ['2017-05-05'] })
      end
    end
  end
end
