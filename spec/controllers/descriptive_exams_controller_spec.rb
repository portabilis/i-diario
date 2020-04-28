require 'spec_helper'

RSpec.describe DescriptiveExamsController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:user) { create(:user, :with_user_role_administrator) }
  let(:user_role) { user.user_roles.first }
  let(:unity) { user_role.unity }
  let(:classroom) { create(:classroom, :with_classroom_semester_steps, unity: unity) }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  before do
    sign_in(user)
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:current_unity).and_return(unity)
    request.env['REQUEST_PATH'] = ''
  end

  describe 'PUT #update' do
    let!(:descriptive_exam) {
      create(
        :descriptive_exam,
        :with_teacher_discipline_classroom,
        classroom: classroom
      )
    }
    let!(:step) { descriptive_exam.step }

    context 'when recorded at has no a valid date in step' do
      before do
        descriptive_exam.recorded_at = step.end_at + 1.day
      end

      it 'updates the descriptive exam' do
        expect(descriptive_exam.save).to be true
      end
    end
  end
end
