# frozen_string_literal: true

require 'rails_helper'

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
    let(:other_student) { create(:student) }
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

    # A requisição roda na conexão da entidade e não enxerga registro criado na conexão padrão. O around
    # envolve os before, então a transação do DatabaseCleaner abre nessa mesma conexão e desfaz as factories.
    around(:each) do |example|
      entity.using_connection { example.run }
    end

    before do
      teacher_discipline_classroom
      previous_enrollment_classroom
      last_enrollment_classroom
      GeneralConfiguration.current.update(show_inactive_enrollments: true)

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
        it 'returns one row per enrollment, both not in the classroom on the date' do
          students = fetched_students

          expect(students.map { |student_row| student_row['id'] }).to eq(
            [previous_enrollment_classroom.student_enrollment_id, last_enrollment_classroom.student_enrollment_id]
          )
          expect(students.map { |student_row| student_row['student']['id'] }).to eq([student.id, student.id])
          expect(students.map { |student_row| student_row['inactive_on_date'] }).to eq([true, true])
        end
      end

      context 'when the student leaves and joins the classroom again on the date' do
        before do
          GeneralConfiguration.current.update(show_inactive_enrollments: false)
          previous_enrollment_classroom.update!(left_at: recorded_at.to_s, show_as_inactive_when_not_in_date: true)
          last_enrollment_classroom.update!(joined_at: recorded_at.to_s, left_at: '')
        end

        it 'returns both enrollments, only the one in the classroom on the date as active' do
          students = fetched_students

          expect(students.map { |student_row| student_row['id'] }).to eq(
            [previous_enrollment_classroom.student_enrollment_id, last_enrollment_classroom.student_enrollment_id]
          )
          expect(students.map { |student_row| student_row['inactive_on_date'] }).to eq([true, false])
        end
      end
    end

    context 'when saving' do
      # O PostingDateChecker só libera a gravação quando a etapa da data do lançamento é a mesma
      # etapa de hoje, então o lançamento nasce na data corrente.
      let(:recorded_at) { Date.current }

      def exam_params(students_attributes)
        {
          unity_id: unity.id,
          classroom_id: classroom.id,
          discipline_id: discipline.id,
          complementary_exam_setting_id: complementary_exam_setting.id,
          step_id: StepsFetcher.new(classroom).step_by_date(recorded_at).try(:id),
          recorded_at: recorded_at.strftime('%d/%m/%Y'),
          students_attributes: students_attributes
        }
      end

      describe '#create' do
        it 'saves the exam without recording the rows of enrollments not in the classroom on the date' do
          post :create, params: {
            locale: 'pt-BR',
            complementary_exam: exam_params(
              '0' => { student_id: other_student.id, score: '1', active: 'true' },
              '1' => { student_id: student.id, score: '', active: 'false' },
              '2' => { student_id: student.id, score: '', active: 'false' }
            )
          }

          complementary_exam = assigns(:complementary_exam)

          expect(complementary_exam).to be_persisted
          expect(complementary_exam.students.reload.map(&:student_id)).to eq([other_student.id])
        end

        it 'lists one row per enrollment when the record is invalid' do
          post :create, params: {
            locale: 'pt-BR',
            complementary_exam: exam_params(
              '0' => { student_id: student.id, score: '', active: 'false' },
              '1' => { student_id: student.id, score: '', active: 'false' }
            )
          }

          listed_students = assigns(:students)

          expect(assigns(:complementary_exam)).not_to be_persisted
          expect(listed_students.map(&:student_id)).to eq([student.id, student.id])
          expect(listed_students.map(&:object_id).uniq.size).to eq(2)
        end
      end

      context 'with the exam already saved' do
        let(:complementary_exam) do
          create(:complementary_exam, unity: unity, classroom: classroom, discipline: discipline,
                                      complementary_exam_setting: complementary_exam_setting,
                                      recorded_at: recorded_at, teacher_id: teacher.id)
        end
        let(:exam_student) do
          complementary_exam.students.first.tap { |exam_student_record| exam_student_record.update!(student: student) }
        end

        # A trava de colunas por perfil compara turma e disciplina do lançamento com as do usuário.
        before do
          exam_student
          user.update_columns(current_classroom_id: classroom.id, current_discipline_id: discipline.id)
        end

        describe '#edit' do
          it 'lists one row per enrollment, with the saved record in a single row' do
            get :edit, params: { locale: 'pt-BR', id: complementary_exam.id }

            listed_students = assigns(:students)

            expect(listed_students.map(&:student_id)).to eq([student.id, student.id])
            expect(listed_students.map(&:id)).to eq([exam_student.id, nil])
          end
        end

        describe '#update' do
          it 'saves the exam keeping a single record for the student' do
            patch :update, params: {
              locale: 'pt-BR',
              id: complementary_exam.id,
              complementary_exam: exam_params(
                '0' => {
                  id: exam_student.id, student_id: student.id, score: exam_student.score.to_s, active: 'false'
                },
                '1' => { student_id: student.id, score: '', active: 'false' }
              )
            }

            expect(response).to redirect_to(complementary_exams_path)
            expect(ComplementaryExamStudent.where(complementary_exam_id: complementary_exam.id).pluck(:id))
              .to eq([exam_student.id])
          end
        end

        context 'when only the last enrollment is in the classroom on the date' do
          before do
            previous_enrollment_classroom.update!(joined_at: (recorded_at - 30).to_s, left_at: (recorded_at - 10).to_s)
            last_enrollment_classroom.update!(joined_at: (recorded_at - 10).to_s, left_at: '')
          end

          it 'lists the saved record in the row of the enrollment in the classroom on the date' do
            get :edit, params: { locale: 'pt-BR', id: complementary_exam.id }

            listed_students = assigns(:students)

            expect(listed_students.map(&:active)).to eq([false, true])
            expect(listed_students.map(&:id)).to eq([nil, exam_student.id])
          end

          it 'saves the score of the row of the enrollment in the classroom on the date' do
            patch :update, params: {
              locale: 'pt-BR',
              id: complementary_exam.id,
              complementary_exam: exam_params(
                '0' => { student_id: student.id, score: '', active: 'false' },
                '1' => { id: exam_student.id, student_id: student.id, score: '0', active: 'true' }
              )
            }

            expect(response).to redirect_to(complementary_exams_path)
            expect(ComplementaryExamStudent.where(complementary_exam_id: complementary_exam.id).pluck(:id, :score))
              .to eq([[exam_student.id, 0]])
          end
        end
      end
    end
  end
end
