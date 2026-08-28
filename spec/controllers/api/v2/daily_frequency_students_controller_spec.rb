require 'rails_helper'

RSpec.describe Api::V2::DailyFrequencyStudentsController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:user) { create(:user) }
  let(:teacher) { create(:teacher) }
  let(:discipline) { create(:discipline) }
  let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
  let!(:teacher_discipline_classroom) do
    create(:teacher_discipline_classroom, classroom: classroom, discipline: discipline, teacher: teacher)
  end
  let(:daily_frequency) do
    create(:daily_frequency, :with_students, classroom: classroom, discipline: discipline, teacher: teacher)
  end
  let(:daily_frequency_student) { daily_frequency.students.first }

  around do |example|
    entity.using_connection { example.run }
  end

  before do
    allow(controller).to receive(:authenticate_api!)
  end

  describe 'PUT #update' do
    it 'enqueues the automatic absence posting on behalf of the diary owner' do
      expect(AutomaticAbsencePostingEnqueuer).to receive(:call).with(
        entity_id: entity.id,
        classroom_id: classroom.id,
        frequency_dates: [daily_frequency.frequency_date],
        teacher_id: teacher.id
      )

      put :update, params: {
        id: daily_frequency_student.id,
        user_id: user.id,
        present: false,
        format: 'json',
        locale: 'en'
      }

      expect(response).to have_http_status(:success)
    end
  end
end
