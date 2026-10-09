require 'rails_helper'

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
  let(:school_calendar) { create(:school_calendar, :with_one_step, unity: unity, opened_year: true) }
  let(:current_teacher) { create(:teacher) }
  let(:other_teacher) { create(:teacher) }
  let(:discipline) { create(:discipline) }
  let(:grade) { create(:grade) }
  let(:classroom) {
    create(
      :classroom,
      :with_teacher_discipline_classroom,
      :with_classroom_trimester_steps,
      :score_type_numeric,
      unity: unity,
      teacher: current_teacher,
      grade: grade,
      discipline: discipline,
      school_calendar: school_calendar
    )
  }

  let(:classrooms_grade) { create(:classrooms_grade, classroom: classroom, grade: grade) }

  let(:params) {
    {
      locale: 'pt-BR',
      class_numbers: '1, 2',
      daily_frequency: {
        classroom_id: classroom.id,
        unity_id: unity.id,
        discipline_id: discipline.id,
        frequency_date: '2017-02-28',
        period: 1
      }
    }
  }

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
    allow(controller).to receive(:current_classroom).and_return(classroom)
    allow(controller).to receive(:current_teacher).and_return(current_teacher)
    allow(controller).to receive(:current_school_calendar).and_return(school_calendar)
    allow(controller).to receive(:current_teacher_id).and_return(current_teacher.id)
    request.env['REQUEST_PATH'] = ''
  end

  describe 'GET #new' do
    context 'when the classroom has a lessons board (quadro de aulas)' do
      let(:teacher_discipline_classroom) do
        TeacherDisciplineClassroom.find_by!(classroom: classroom, teacher: current_teacher, discipline: discipline)
      end
      let(:lessons_board) { create(:lessons_board, classrooms_grade: classrooms_grade) }
      let(:lesson) { create(:lessons_board_lesson, lessons_board: lessons_board, lesson_number: 3) }

      before do
        create(
          :lessons_board_lesson_weekday,
          lessons_board_lesson: lesson,
          teacher_discipline_classroom: teacher_discipline_classroom,
          weekday: :thursday
        )
      end

      it 'embeds the teacher lessons board allocations for JS to filter "Aula" instantly' do
        get :new, params: { locale: 'pt-BR' }

        expect(assigns(:lessons_board_allocations)).to include(
          classroom_id: classroom.id,
          discipline_id: discipline.id,
          weekday: 'thursday',
          lesson_number: lesson.lesson_number.to_i
        )
      end

      it 'includes the classroom in classroom_ids_with_lessons_board' do
        get :new, params: { locale: 'pt-BR' }

        expect(assigns(:classroom_ids_with_lessons_board)).to include(classroom.id)
      end
    end

    context 'when the classroom has no lessons board' do
      it 'does not include the classroom in classroom_ids_with_lessons_board (JS keeps the old full list)' do
        get :new, params: { locale: 'pt-BR' }

        expect(assigns(:classroom_ids_with_lessons_board)).not_to include(classroom.id)
      end

      it 'has no allocations for a teacher with no lessons board at all' do
        get :new, params: { locale: 'pt-BR' }

        expect(assigns(:lessons_board_allocations)).to eq([])
      end
    end
  end

  describe 'POST #create' do
    context 'without success' do
      it 'fails to create and renders the new template' do
        allow(school_calendar).to receive(:day_allows_entry?).and_return(false)
        post :create, params: params
        expect(response).to render_template(:new)
      end
    end

    context 'with success' do
      it 'creates and redirects to daily frequency edit page' do
        post :create, params: params
        expect(response).to redirect_to /#{edit_multiple_daily_frequencies_path}/
      end
    end
  end

  describe 'GET #edit_multiple' do
    before do
      allow(controller).to receive(:discipline_classroom_grade_ids).and_return([1, 2, classrooms_grade.grade_id])
    end

    context 'without success' do
      it 'returns not found status' do
        get :edit_multiple, params: params
        expect(response).to have_http_status(302)
      end
    end

    context 'with success' do
      it 'returns success status' do
        create(:student_enrollment_classroom, classrooms_grade: classrooms_grade)
        params[:class_numbers] = [1, 2, classrooms_grade.grade_id]
        get :edit_multiple, params: params
        expect(response).to have_http_status(200)
      end
    end
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
          delete :destroy_multiple, params: { locale: 'pt-BR', daily_frequencies_ids: daily_frequencies_ids }
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

    it 'enqueues the automatic absence posting of the classroom forcing the resend' do
      expect(AutomaticAbsencePostingEnqueuer).to receive(:call).with(
        entity_id: entity.id,
        classroom_id: daily_frequency_1.classroom_id,
        frequency_dates: [daily_frequency_1.frequency_date],
        teacher_id: current_teacher.id,
        force_posting: true
      )

      delete :destroy_multiple, params: { locale: 'pt-BR', daily_frequencies_ids: [daily_frequency_1.id] }
    end

    it 'covers every classroom and date of the deleted frequencies' do
      allow(UniqueDailyFrequencyStudentsCreator).to receive(:call_worker)

      expect(AutomaticAbsencePostingEnqueuer).to receive(:call).with(
        hash_including(
          classroom_id: daily_frequency_1.classroom_id,
          frequency_dates: [daily_frequency_1.frequency_date],
          force_posting: true
        )
      )
      expect(AutomaticAbsencePostingEnqueuer).to receive(:call).with(
        hash_including(
          classroom_id: daily_frequency_2.classroom_id,
          frequency_dates: [daily_frequency_2.frequency_date],
          force_posting: true
        )
      )

      delete :destroy_multiple, params: {
        locale: 'pt-BR',
        daily_frequencies_ids: [daily_frequency_1.id, daily_frequency_2.id]
      }
    end

    context 'when the posting period of the step is over' do
      # A turma nasce com duas etapas semestrais; a data congelada cai na segunda, então a janela
      # de lançamento da primeira já venceu.
      let(:current_date) { Date.new(Date.current.year, 8, 15) }
      let(:blocked_classroom) { create(:classroom, :with_classroom_semester_steps) }
      let!(:blocked_daily_frequency) do
        create(
          :daily_frequency,
          :with_students,
          students_count: 2,
          classroom: blocked_classroom,
          frequency_date: Date.new(current_date.year, 5, 15)
        )
      end

      around do |example|
        Timecop.freeze(current_date) { example.run }
      end

      it 'keeps the daily frequency, skips the workers and warns the user' do
        expect(UniqueDailyFrequencyStudentsCreator).to_not receive(:call_worker)
        expect(AutomaticAbsencePostingEnqueuer).to_not receive(:call)

        expect {
          delete :destroy_multiple, params: {
            locale: 'pt-BR',
            daily_frequencies_ids: [blocked_daily_frequency.id]
          }
        }.to_not change(DailyFrequency, :count)

        expect(
          DailyFrequencyStudent.with_discarded.by_daily_frequency_id(blocked_daily_frequency.id).count
        ).to eq(2)
        expect(response).to redirect_to(new_daily_frequency_path)
        expect(flash[:alert]).to eq('Não é possível apagar registros fora das datas de lançamento da etapa.')
      end
    end
  end

  describe '#check_and_preserve_existing_justifications' do
    # Esse teste verifica que o controller chama o AbsenceJustificationPreserver corretamente
    let(:frequency_date) { school_calendar.steps.first.start_at }
    let(:student) { create(:student) }
    let(:student_enrollment) { create(:student_enrollment, student: student) }
    let!(:student_enrollment_classroom) do
      create(
        :student_enrollment_classroom,
        student_enrollment: student_enrollment,
        classrooms_grade: classrooms_grade
      )
    end

    let(:daily_frequency_students_params) do
      {
        class_number: 1,
        students_attributes: {
          '0' => {
            student_id: student.id,
            present: true,
            absence_justification_student_id: nil
          }
        }
      }
    end

    let(:daily_frequency_attributes) do
      {
        frequency_date: frequency_date,
        classroom_id: classroom.id,
        period: Periods::MATUTINAL
      }
    end

    it 'calls AbsenceJustificationPreserver with correct parameters' do
      expect(AbsenceJustificationPreserver).to receive(:call).with(
        frequency_date: frequency_date,
        classroom_id: classroom.id,
        period: Periods::MATUTINAL,
        class_number: 1,
        student_ids: [student.id]
      ).and_return({})

      controller.send(
        :check_and_preserve_existing_justifications,
        daily_frequency_students_params,
        daily_frequency_attributes
      )
    end

    it 'applies justifications returned by the service' do
      justification_id = 999

      allow(AbsenceJustificationPreserver).to receive(:call).and_return(
        student.id => justification_id
      )

      controller.send(
        :check_and_preserve_existing_justifications,
        daily_frequency_students_params,
        daily_frequency_attributes
      )

      student_data = daily_frequency_students_params[:students_attributes]['0']
      expect(student_data[:present]).to be false
      expect(student_data[:absence_justification_student_id]).to eq(justification_id)
    end
  end
end
