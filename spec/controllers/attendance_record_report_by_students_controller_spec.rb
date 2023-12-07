require 'spec_helper'

RSpec.describe AttendanceRecordReportByStudentsController, type: :controller do
  let(:current_teacher) { create(:teacher) }
  let(:unity) { create(:unity) }
  let(:classroom) {
    create(
      :classroom,
      :with_teacher_discipline_classroom,
      :with_classroom_trimester_steps,
      :score_type_numeric,
      unity: unity,
      teacher: current_teacher
    )
  }

  before do
    allow(controller).to receive(:current_classroom).and_return(classroom)
    allow(controller).to receive(:current_teacher).and_return(current_teacher)
  end

  describe 'GET #form' do
    it 'returns http success' do
      get :form
      expect(response).to have_http_status(:success)
    end
  end
end
