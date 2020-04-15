require 'spec_helper'

RSpec.describe DailyFrequenciesController, type: :controller do
  let(:entity) { Entity.find_by(domain: 'test.host') }
  let(:user) do
    create(
      :user_with_user_role,
      admin: false,
      teacher_id: current_teacher.id,
      current_unity_id: unity.id,
      current_school_year: classroom.year,
      current_classroom_id: classroom.id,
      current_discipline_id: discipline.id
    )
  end
  let(:user_role) { user.user_roles.first }
  let(:unity) { create(:unity) }
  let(:current_teacher) { create(:teacher) }
  let(:other_teacher) { create(:teacher) }
  let(:classroom) { create(:classroom) }
  let(:discipline) { create(:discipline) }

  around(:each) do |example|
    entity.using_connection do
      example.run
    end
  end

  before do
    user_role.unity = unity
    user_role.save!

    user.current_user_role = user_role
    user.save!

    sign_in(user)
    allow(controller).to receive(:authorize).and_return(true)
    allow(controller).to receive(:current_user_is_employee_or_administrator?).and_return(false)
    allow(controller).to receive(:can_change_school_year?).and_return(true)
    request.env['REQUEST_PATH'] = ''
  end

  describe 'DELETE #destroy_multiple' do
    let!(:daily_frequency_1) {
      create(
        :daily_frequency,
        :with_students,
        students_count: 3
      )
    }
    let!(:daily_frequency_2) {
      create(
        :daily_frequency,
        :with_students,
        students_count: 3
      )
    }
    let!(:daily_frequency_3) {
      create(
        :daily_frequency,
        :with_students,
        students_count: 3
      )
    }

    shared_examples 'delete_all_frequencies' do
      it 'deletes all daily_frequencies and daily_frequency_students' do
        daily_frequencies_ids = [daily_frequency_1.id, daily_frequency_2.id]

        expect {
          delete :destroy_multiple, locale: 'pt-BR', daily_frequencies_ids: daily_frequencies_ids
        }.to change(DailyFrequency, :count).by(-2)
      end
    end

    context 'when just has daily_frequencies and daily_frequency_students' do
      it_behaves_like 'delete_all_frequencies'
    end

    context 'when has discarded daily_frequency_students' do
      before do
        daily_frequency_1.students.last.discard
      end

      it_behaves_like 'delete_all_frequencies'
    end
  end
end
