# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ActiveStudentsOnDate, type: :service do

  context '#call' do
    let!(:enrollment_classroom) { create(:student_enrollment_classroom) }

    it 'should returns student_enrollment active on date' do
      subject = described_class.call(
        student_enrollments: enrollment_classroom.student_enrollment_id,
        date: '2018-01-01'
      )

      expect(subject).to include({ enrollment_classroom.id => ['2018-01-01'] })
    end

    let!(:enrollment_classroom_2) {
      create(
        :student_enrollment_classroom,
        left_at: '2017-12-12'
      )
    }
    it 'should returns hash empty for student inactive on date' do
      subject = described_class.call(
        student_enrollments: enrollment_classroom_2.student_enrollment_id,
        date: '2018-01-01'
      )

      expect(subject).to be_empty
    end
  end
end
