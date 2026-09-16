# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplementaryExamsController, type: :controller do
  describe '#index' do
    let(:entity) { Entity.find_by(domain: 'test.host') }
    let(:user) { create(:user, :with_user_role_administrator) }
    let(:teacher) { create(:teacher) }
    let(:unity) { create(:unity) }
    let(:school_calendar) { create(:school_calendar, :with_one_step, unity: unity) }
    let(:classroom) { create(:classroom, unity: unity, school_calendar: school_calendar) }
    let(:discipline) { create(:discipline) }
    let!(:teacher_discipline_classroom) do
      create(:teacher_discipline_classroom,
             teacher: teacher,
             discipline: discipline,
             classroom: classroom)
    end

    before do
      entity.using_connection do
        sign_in(user)

        # Mock all required methods
        allow(controller).to receive(:authorize).and_return(true)
        allow(controller).to receive(:require_current_teacher).and_return(true)
        allow(controller).to receive(:require_allow_to_modify_prev_years).and_return(true)
        allow(controller).to receive(:current_teacher).and_return(teacher)
        allow(controller).to receive(:current_teacher_id).and_return(teacher.id)
        allow(controller).to receive(:current_unity).and_return(unity)
        allow(controller).to receive(:current_school_year).and_return(Date.current.year)
        allow(controller).to receive(:current_user_classroom).and_return(classroom)
        allow(controller).to receive(:current_user_discipline).and_return(discipline)
      end
    end

    it 'does not raise error when filtering by step_id' do
      entity.using_connection do
        expect do
          get :index, params: { locale: 'pt-BR', filter: { by_step_id: school_calendar.steps.first.id } }
        end.not_to raise_error
      end
    end

    it 'calls set_options_by_user which sets @classrooms' do
      entity.using_connection do
        get :index, params: { locale: 'pt-BR' }
        expect(assigns(:classrooms)).not_to be_nil
      end
    end
  end

  describe 'student with more than one enrollment in the classroom' do
    let(:entity) { Entity.find_by(domain: 'test.host') }
    let(:user) { create(:user, :with_user_role_administrator) }
    let(:teacher) { create(:teacher) }
    let(:unity) { create(:unity) }
    let(:classroom) { create(:classroom, :with_classroom_trimester_steps, unity: unity) }
    let(:classrooms_grade) { create(:classrooms_grade, :score_type_numeric, classroom: classroom) }
    let(:discipline) { create(:discipline) }
    let(:student) { create(:student) }
    let(:year) { classroom.year.to_i }
    let(:recorded_at) { Date.new(year, 8, 1) }
    let(:teacher_discipline_classroom) do
      create(:teacher_discipline_classroom, teacher: teacher, discipline: discipline, classroom: classroom)
    end
    let(:complementary_exam_setting) do
      create(:complementary_exam_setting, year: year, grades: [classrooms_grade.grade])
    end
    # Cada entrada do aluno na turma vira uma matrícula própria no i-Educar, então o mesmo aluno tem
    # duas matrículas na mesma turma.
    let(:previous_enrollment_classroom) do
      create(:student_enrollment_classroom,
             student_enrollment: create(:student_enrollment, student: student),
             classrooms_grade: classrooms_grade,
             joined_at: "#{year}-02-01",
             left_at: "#{year}-03-01",
             sequence: 1)
    end
    let(:last_enrollment_classroom) do
      create(:student_enrollment_classroom,
             student_enrollment: create(:student_enrollment, student: student),
             classrooms_grade: classrooms_grade,
             joined_at: "#{year}-04-01",
             left_at: "#{year}-05-01",
             sequence: 2)
    end

    # As factories precisam rodar na conexão da entidade: a requisição roda dentro dela e não enxerga
    # registro criado na conexão padrão.
    before do
      entity.using_connection do
        teacher_discipline_classroom
        previous_enrollment_classroom
        last_enrollment_classroom

        sign_in(user)

        allow(controller).to receive(:authorize).and_return(true)
        allow(controller).to receive(:require_current_teacher).and_return(true)
        allow(controller).to receive(:require_allow_to_modify_prev_years).and_return(true)
        allow(controller).to receive(:current_teacher).and_return(teacher)
        allow(controller).to receive(:current_teacher_id).and_return(teacher.id)
        allow(controller).to receive(:current_unity).and_return(unity)
        allow(controller).to receive(:current_school_year).and_return(year)
        allow(controller).to receive(:current_user_classroom).and_return(classroom)
        allow(controller).to receive(:current_user_discipline).and_return(discipline)
      end
    end

    describe '#fetch_students' do
      def fetched_students
        get :fetch_students, params: {
          locale: 'pt-BR',
          classroom_id: classroom.id,
          discipline_id: discipline.id,
          date: recorded_at.to_s,
          format: :json
        }

        JSON.parse(response.body)['students']
      end

      context 'when the entity shows inactive enrollments and none of them covers the date' do
        before do
          entity.using_connection { GeneralConfiguration.current.update(show_inactive_enrollments: true) }
        end

        it 'returns the student once, marked as not in the classroom on the date' do
          entity.using_connection do
            students = fetched_students

            expect(students.map { |student_row| student_row['student']['id'] }).to eq([student.id])
            expect(students.first['inactive_on_date']).to eq(true)
          end
        end
      end

      context 'when the student leaves and joins the classroom again on the date' do
        before do
          entity.using_connection do
            GeneralConfiguration.current.update(show_inactive_enrollments: false)
            previous_enrollment_classroom.update!(left_at: recorded_at.to_s, show_as_inactive_when_not_in_date: true)
            last_enrollment_classroom.update!(joined_at: recorded_at.to_s, left_at: '')
          end
        end

        it 'returns the enrollment that is in the classroom on the date' do
          entity.using_connection do
            students = fetched_students

            expect(students.map { |student_row| student_row['student']['id'] }).to eq([student.id])
            expect(students.first['id']).to eq(last_enrollment_classroom.student_enrollment_id)
            expect(students.first['inactive_on_date']).to eq(false)
          end
        end
      end
    end

    describe '#create' do
      before do
        entity.using_connection { GeneralConfiguration.current.update(show_inactive_enrollments: true) }
      end

      it 'lists the student once when the record is invalid' do
        entity.using_connection do
          post :create, params: {
            locale: 'pt-BR',
            complementary_exam: {
              unity_id: unity.id,
              classroom_id: classroom.id,
              discipline_id: discipline.id,
              complementary_exam_setting_id: complementary_exam_setting.id,
              step_id: StepsFetcher.new(classroom).step_by_date(recorded_at).try(:id),
              recorded_at: recorded_at.strftime('%d/%m/%Y'),
              students_attributes: { '0' => { student_id: student.id, score: '' } }
            }
          }

          expect(assigns(:complementary_exam)).not_to be_persisted
          expect(assigns(:students).map(&:student_id)).to eq([student.id])
        end
      end
    end
  end
end
