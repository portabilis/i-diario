require 'rails_helper'

RSpec.describe DailyNoteCreator, type: :service do
  let(:avaliation) {
    create(
      :avaliation,
      :with_teacher_discipline_classroom
    )
  }

  it 'create daily note when avaliation is passed by parameter' do
    creator = described_class.new(
      avaliation_id: avaliation.id
    )

    expect { creator.find_or_create }.to change { DailyNote.count }.to(1)
  end

  context 'exist student enrollments' do
    let(:student_enrollment) { create(:student_enrollment) }

    before do
      StudentEnrollmentClassroom.create!(
        classroom: avaliation.classroom,
        student_enrollment: student_enrollment,
        joined_at: Date.current.beginning_of_year,
        left_at: ''
      )
    end

    it 'create daily note students' do
      creator = described_class.new(
        avaliation_id: avaliation.id
      )

      expect { creator.find_or_create }.to change { DailyNoteStudent.count }.to(1)
    end
  end
end
