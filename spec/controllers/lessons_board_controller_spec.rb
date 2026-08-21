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

  let(:other_user) do
    create(:user)
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

  describe '#index' do
    let(:previous_year_classroom) { create(:classroom, unity: classroom.unity, year: classroom.year - 1) }
    let!(:lessons_board_previous_year) do
      create(:lessons_board, classrooms_grade: create(:classrooms_grade, classroom: previous_year_classroom))
    end

    context 'when user have access' do
      it 'list all lessons board' do
        get :index, params: { locale: 'pt-BR', search: { by_year: '' } }

        expect(assigns(:lessons_boards).size).to eq(3)
      end
    end

    context 'when user dont have access' do
      it 'dont list any lessons board' do
        sign_in(other_user)

        get :index, params: { locale: 'pt-BR' }

        expect(assigns(:lessons_boards)).to be_empty
      end
    end

    context 'when there is no search param' do
      it 'filters by the school year selected on the user profile' do
        get :index, params: { locale: 'pt-BR' }

        expect(assigns(:filtering_params)[:by_year]).to eq(classroom.year.to_s)
        expect(assigns(:lessons_boards)).to match_array([lessons_board_1, lessons_board_2])
      end

      it 'falls back to the profile year when the search param is malformed' do
        get :index, params: { locale: 'pt-BR', search: 'invalid' }

        expect(assigns(:filtering_params)[:by_year]).to eq(classroom.year.to_s)
      end
    end

    context 'when the year filter is cleared' do
      it 'lists lessons boards of every year' do
        get :index, params: { locale: 'pt-BR', search: { by_year: '' } }

        expect(assigns(:lessons_boards)).to match_array(
          [lessons_board_1, lessons_board_2, lessons_board_previous_year]
        )
      end

      it 'includes the year on the classroom options' do
        get :index, params: { locale: 'pt-BR', search: { by_year: '' } }

        expect(assigns(:classrooms_options).map(&:name)).to include(
          "#{classroom.description} - #{classroom.year}"
        )
      end
    end

    context 'when the year filter is incomplete' do
      it 'ignores the year' do
        get :index, params: { locale: 'pt-BR', search: { by_year: '20' } }

        expect(assigns(:filtering_params)[:by_year]).to eq('')
        expect(assigns(:lessons_boards).size).to eq(3)
      end
    end

    context 'when a filter is not valid anymore' do
      it 'treats the empty value of select2 as no filter' do
        get :index, params: { locale: 'pt-BR', search: { by_unity: 'empty' } }

        expect(assigns(:filtering_params)[:by_unity]).to eq('')
      end

      it 'keeps the selected unity when it has no lessons board on the filtered year' do
        get :index, params: {
          locale: 'pt-BR', search: { by_year: '1999', by_unity: classroom.unity.id.to_s }
        }

        expect(assigns(:filtering_params)[:by_unity]).to eq(classroom.unity.id.to_s)
        expect(assigns(:unities_options)).to include(classroom.unity)
        expect(assigns(:lessons_boards).to_a).to eq([])
      end

      it 'discards a unity the user has no access to' do
        get :index, params: { locale: 'pt-BR', search: { by_unity: unity.id.to_s } }

        expect(assigns(:filtering_params)[:by_unity]).to eq('')
        expect(assigns(:lessons_boards)).to match_array([lessons_board_1, lessons_board_2])
      end

      it 'discards a grade without lessons boards' do
        grade_without_lessons_board = create(:grade)

        get :index, params: { locale: 'pt-BR', search: { by_grade: grade_without_lessons_board.id.to_s } }

        expect(assigns(:filtering_params)[:by_grade]).to eq('')
      end

      it 'discards a classroom without lessons boards' do
        classroom_without_lessons_board = create(:classroom, unity: classroom.unity, year: classroom.year)

        get :index, params: {
          locale: 'pt-BR', search: { by_classroom: classroom_without_lessons_board.id.to_s }
        }

        expect(assigns(:filtering_params)[:by_classroom]).to eq('')
      end
    end
  end

  describe '#create' do
    context 'with success' do
      it 'valid params' do
        params = json_file_fixture('/spec/fixtures/files/full_lessons_board.json')

        expect{(
          post :create, params: {  locale: 'pt-BR', lessons_board: params }
        )}.to change{ LessonsBoard.count }.to(3)
      end
    end

    context 'without success' do
      it 'invalid params' do
        params = json_file_fixture('/spec/fixtures/files/without_classrooms_grade_lessons_board.json')

        expect {(
          post :create, params: {  locale: 'pt-BR', lessons_board: params }
        )}.to_not change(LessonsBoard, :count)
      end
    end
  end

  describe '#update' do
    context 'with success' do
      it 'when teacher allocation is changed with success' do
        params = json_file_fixture('/spec/fixtures/files/full_lessons_board.json')

        post :create, params: {  locale: 'pt-BR', lessons_board: params }

        last_lessons_board = LessonsBoard.last
        first_lesson = last_lessons_board.lessons_board_lessons.first
        first_allocation = last_lessons_board.lessons_board_lessons.first.lessons_board_lesson_weekdays.first
        update_lessons_board = {
          id: last_lessons_board.id,
          "lessons_board_lessons_attributes": {
            "0": {
              "id": first_lesson.id,
              "lesson_number": "1",
              "_destroy": "false",
              "lessons_board_lesson_weekdays_attributes": {
                "0": {
                  "id": first_allocation.id,
                  "weekday": "monday",
                  "teacher_discipline_classroom_id": "94000"
                }
              }
            }
          }
        }

        expect {(
          patch :update, params: { locale: 'pt-BR', id: last_lessons_board.id, lessons_board: update_lessons_board }
        )}.to change { first_allocation.reload.teacher_discipline_classroom_id }.from(84167).to(94000)
      end
    end
  end

  describe '#destroy' do
    context 'with success' do
      it 'when delete one lessons board' do
        expect{(
          delete :destroy, params: { locale: 'pt-BR', id: lessons_board_1.id }
        )}.to change{ LessonsBoard.count }.to(1)
      end
    end
  end
end
