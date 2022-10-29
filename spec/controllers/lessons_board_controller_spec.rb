require 'rails_helper'

RSpec.describe LessonsBoardsController, type: :controller do
  let(:user) do
    create(
      :user,
      :with_user_role_administrator,
      admin: true,
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
  let(:classroom) { create(:classroom, :with_classroom_trimester_steps) }
  let(:discipline) { create(:discipline) }
  let!(:classroom_grade) { create(:classrooms_grade, classroom: classroom) }
  let!(:classroom_grade_2) { create(:classrooms_grade, classroom: classroom) }
  let!(:lessons_board_1) { create(:lessons_board, classrooms_grade: classroom_grade) }
  let!(:lessons_board_2) { create(:lessons_board, classrooms_grade: classroom_grade_2) }

  around(:each) do |example|
    Entity.find_by_domain("test.host").using_connection do
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
    allow(controller).to receive(:current_unity).and_return(unity)
    request.env['REQUEST_PATH'] = ''
  end

  context '#index' do
    it 'when list all lessons board' do
      get :index, locale: 'pt-BR'

      expect(assigns(:lessons_boards).size).to eq(2)
    end
  end

  context '#create' do
    it 'when create a new lessons board' do
      params = json_file_fixture('/spec/fixtures/files/full_lessons_board.json')

      expect{(
        post :create,  locale: 'pt-BR', lessons_board: params
      )}.to change{ LessonsBoard.count }.to(3)
    end
  end


  context '#destroy' do
    it 'when delete one lessons board'
  end
end
