require 'rails_helper'

RSpec.describe DailyNoteCreator, type: :service do
  let(:avaliation) { create(:current_avaliation) }
  let(:classroom) { avaliation.classroom }

  it 'create daily note when avaliation is passed by parameter' do
    creator = described_class.new({
      avaliation_id: avaliation.id
    })

    expect { creator.find_or_create! }.to change { DailyNote.count }.to(1)
  end

  context 'exist student enrollments' do
    let(:student_enrollment) { create(:student_enrollment) }

    before do
      StudentEnrollmentClassroom.create!(
        classroom: classroom,
        student_enrollment: student_enrollment,
        joined_at: Date.today.beginning_of_year
      )
    end

    it 'create daily note students' do
      creator = described_class.new({
        avaliation_id: avaliation.id
      })

      expect { creator.find_or_create! }.to change { DailyNoteStudent.count }.to(1)
    end
  end
end
