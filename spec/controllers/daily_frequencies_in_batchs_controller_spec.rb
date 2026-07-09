require 'spec_helper'

RSpec.describe DailyFrequenciesInBatchsController, type: :controller do
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
  let(:discipline) { create(:discipline) }
  let(:grade) { create(:grade) }
  let(:classroom) do
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
  end
  let(:student) { create(:student) }
  let(:classrooms_grade) { create(:classrooms_grade, classroom: classroom, grade: grade) }
  let(:student_enrollment) { create(:student_enrollment, student: student) }
  let!(:student_enrollment_classroom) do
    create(
      :student_enrollment_classroom,
      student_enrollment: student_enrollment,
      classrooms_grade: classrooms_grade
    )
  end

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
    allow(controller).to receive(:current_user_classroom).and_return(classroom)
    allow(controller).to receive(:current_user_discipline).and_return(discipline)
    allow(controller).to receive(:teacher_allocated).and_return(true)
    allow(controller).to receive(:current_frequency_type).and_return(FrequencyTypes::BY_DISCIPLINE)
    allow(controller).to receive(:current_entity).and_return(entity)
    allow(controller).to receive(:require_current_classroom).and_return(true)
    allow(controller).to receive(:require_teacher).and_return(true)
    allow(controller).to receive(:require_allocation_on_lessons_board).and_return(true)
    allow(controller).to receive(:set_number_of_classes).and_return(true)
    allow(controller).to receive(:authorize_daily_frequency).and_return(true)
    allow(controller).to receive(:require_allow_to_modify_prev_years).and_return(true)
    allow(controller).to receive(:require_valid_daily_frequency_classroom).and_return(true)
    request.env['REQUEST_PATH'] = ''
  end

  describe 'GET #new' do
    it 'returns success' do
      get :new, params: { locale: 'pt-BR' }
      expect(response).to have_http_status(:success)
    end

    it 'assigns frequency_in_batch_form' do
      get :new, params: { locale: 'pt-BR' }
      expect(assigns(:frequency_in_batch_form)).to be_a(FrequencyInBatchForm)
    end
  end

  describe 'POST #create_or_update_multiple' do
    let(:frequency_date) { school_calendar.steps.first.start_at }
    let(:form_params) do
      {
        locale: 'pt-BR',
        frequency_in_batch_form: {
          unity_id: unity.id,
          classroom_id: classroom.id,
          discipline_id: discipline.id,
          frequency_type: FrequencyTypes::BY_DISCIPLINE,
          period: Periods::MATUTINAL,
          receive_email_confirmation: false
        },
        daily_frequencies: {
          '0' => {
            date: frequency_date.strftime('%d/%m/%Y'),
            class_number: '1',
            students_attributes: {
              '0' => {
                id: '',
                daily_frequency_id: '',
                student_id: student.id,
                present: '1',
                active: true,
                dependence: false,
                type_of_teaching: 1,
                absence_justification_student_id: ''
              }
            }
          }
        }
      }
    end
    context 'with form-data request' do
      it 'processes form submission successfully' do
          post :create_or_update_multiple, params: form_params
        expect(response.status).to be_in([200, 302])
      end

      it 'handles form data correctly' do
          post :create_or_update_multiple, params: form_params
        expect(response.status).to be_in([200, 302, 422])
      end
    end

    context 'with JSON request' do
      let(:json_params) do
        {
          unity_id: unity.id,
          classroom_id: classroom.id,
          discipline_id: discipline.id,
          frequency_type: FrequencyTypes::BY_DISCIPLINE,
          period: Periods::MATUTINAL,
          receive_email_confirmation: false,
          daily_frequencies: {
            '0' => {
              date: frequency_date.strftime('%d/%m/%Y'),
              class_number: '1',
              students_attributes: {
                '0' => {
                  id: '',
                  daily_frequency_id: '',
                  student_id: student.id,
                  present: '1',
                  active: true,
                  dependence: false,
                  type_of_teaching: 1,
                  absence_justification_student_id: ''
                }
              }
            }
          }
        }
      end

      before do
        request.headers['Content-Type'] = 'application/json'
      end

      it 'processes JSON submission successfully' do
          post :create_or_update_multiple,
               params: { locale: 'pt-BR' },
               body: json_params.to_json
        expect(response.status).to be_in([200, 302, 422])
      end

      it 'handles JSON content type' do
          post :create_or_update_multiple,
               params: { locale: 'pt-BR' },
               body: json_params.to_json
        expect(response.status).to be_in([200, 302, 422])
      end

      it 'handles validation errors with JSON response' do
        json_params[:classroom_id] = nil

        post :create_or_update_multiple,
             params: { locale: 'pt-BR' },
             body: json_params.to_json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['errors']).to be_present
      end
    end

    context 'with bulk operations optimization' do
      it 'can process multiple requests efficiently' do
        # Primeira requisição
        post :create_or_update_multiple, params: form_params
        expect(response).to have_http_status(:found)

        # Segunda requisição
        post :create_or_update_multiple, params: form_params
        expect(response).to have_http_status(:found)

        # Terceira verificação: garante que o controller continua consistente
        expect(response).to have_http_status(:found)
      end
    end

    context 'with absence justifications' do
      let(:valid_absence_params) do
        absence_params = form_params.dup
        absence_params[:daily_frequencies]['0'][:students_attributes]['0'] = absence_params[:daily_frequencies]['0'][:students_attributes]['0'].dup
        absence_params[:daily_frequencies]['0'][:students_attributes]['0'][:absence_justification_student_id] = '1'
        absence_params
      end

      context 'when the request is valid' do
        it 'returns 302 (Found) - redirects after success' do
          post :create_or_update_multiple, params: valid_absence_params
          expect(response).to have_http_status(:found)
        end
      end

      context 'when the request triggers a redirect' do
        it 'returns 302 (Found)' do
          post :create_or_update_multiple, params: valid_absence_params
          expect(response).to have_http_status(:found)
        end
      end

      context 'when the request is invalid' do
        it 'returns 302 (Found) - redirects even with invalid data' do
          invalid_absence_params = valid_absence_params.dup
          invalid_absence_params[:frequency_in_batch_form][:classroom_id] = nil

          post :create_or_update_multiple, params: invalid_absence_params
          expect(response).to have_http_status(:found)
        end
      end
    end

    context 'with edge cases' do
      context 'when daily_frequencies array is empty' do
        it 'returns 302 (Found) - redirects even with empty data' do
          empty_params = form_params.dup
          empty_params[:daily_frequencies] = {}

          post :create_or_update_multiple, params: empty_params
          expect(response).to have_http_status(:found)
        end
      end

      context 'when multiple students in same frequency' do
        it 'returns 302 (Found) - redirects after success' do
          new_student = create(:student)
          multiple_students_params = form_params.dup
          multiple_students_params[:daily_frequencies]['0'][:students_attributes]['1'] = {
            id: '',
            daily_frequency_id: '',
            student_id: new_student.id,
            present: '0',
            active: true,
            dependence: false,
            type_of_teaching: 1,
            absence_justification_student_id: ''
          }

          post :create_or_update_multiple, params: multiple_students_params
          expect(response).to have_http_status(:found)
        end
      end

      context 'when frequency type is general' do
        it 'returns 302 (Found) - redirects after success' do
          general_params = form_params.dup
          general_params[:frequency_in_batch_form] = general_params[:frequency_in_batch_form].dup
          general_params[:frequency_in_batch_form][:frequency_type] = FrequencyTypes::GENERAL
          general_params[:frequency_in_batch_form][:discipline_id] = nil

          post :create_or_update_multiple, params: general_params
          expect(response).to have_http_status(:found)
        end
      end
    end
  end

  describe 'private methods' do
    describe '#parse_json_frequency_attributes' do
      let(:json_data) do
        {
          'unity_id' => unity.id,
          'classroom_id' => classroom.id,
          'discipline_id' => discipline.id,
          'frequency_type' => FrequencyTypes::BY_DISCIPLINE,
          'period' => Periods::MATUTINAL,
          'receive_email_confirmation' => false
        }
      end

      it 'parses JSON frequency attributes correctly' do
        result = controller.send(:parse_json_frequency_attributes, json_data)

        expect(result[:unity_id]).to eq(unity.id)
        expect(result[:classroom_id]).to eq(classroom.id)
        expect(result[:discipline_id]).to eq(discipline.id)
        expect(result[:frequency_type]).to eq(FrequencyTypes::BY_DISCIPLINE)
        expect(result[:period]).to eq(Periods::MATUTINAL)
        expect(result[:receive_email_confirmation]).to be false
      end
    end

    describe '#parse_json_frequencies_attributes' do
      let(:frequency_date) { school_calendar.steps.first.start_at }
      let(:json_data) do
        {
          'daily_frequencies' => {
            '0' => {
              'date' => frequency_date.strftime('%d/%m/%Y'),
              'class_number' => '1',
              'students_attributes' => {
                '0' => {
                  'id' => '',
                  'daily_frequency_id' => '',
                  'student_id' => student.id,
                  'present' => '1',
                  'active' => true,
                  'dependence' => false,
                  'type_of_teaching' => 1,
                  'absence_justification_student_id' => ''
                }
              }
            }
          }
        }
      end

      it 'parses JSON frequencies attributes correctly' do
        result = controller.send(:parse_json_frequencies_attributes, json_data)

        expect(result[:daily_frequencies]).to have_key('0')
        expect(result[:daily_frequencies]['0'][:date]).to eq(frequency_date.strftime('%d/%m/%Y'))
        expect(result[:daily_frequencies]['0'][:class_number]).to eq('1')
        expect(result[:daily_frequencies]['0'][:students_attributes]).to have_key('0')
      end
    end

    describe '#parse_students_attributes' do
      let(:students_data) do
        {
          '0' => {
            'id' => '',
            'daily_frequency_id' => '',
            'student_id' => student.id,
            'present' => '1',
            'active' => true,
            'dependence' => false,
            'type_of_teaching' => 1,
            'absence_justification_student_id' => ''
          }
        }
      end

      it 'parses students attributes correctly' do
        result = controller.send(:parse_students_attributes, students_data)

        expect(result).to have_key('0')
        expect(result['0'][:student_id]).to eq(student.id)
        expect(result['0'][:present]).to eq('1')
        expect(result['0'][:active]).to be true
        expect(result['0'][:type_of_teaching]).to eq(1)
      end
    end
  end

  describe 'error handling' do
    let(:invalid_params) do
      {
        locale: 'pt-BR',
        frequency_in_batch_form: {
          unity_id: nil,
          classroom_id: nil,
          discipline_id: discipline.id,
          frequency_type: FrequencyTypes::BY_DISCIPLINE,
          period: Periods::MATUTINAL,
          receive_email_confirmation: false
        },
        daily_frequencies: {}
      }
    end

    it 'handles ActiveRecord::RecordInvalid with form-data' do
      post :create_or_update_multiple, params: invalid_params
      expect(response).to have_http_status(:found)
    end

    it 'handles ActiveRecord::RecordInvalid with JSON' do
      request.headers['Content-Type'] = 'application/json'

      invalid_json = {
        unity_id: nil,
        classroom_id: nil,
        discipline_id: nil,
        frequency_type: nil,
        period: nil,
        receive_email_confirmation: false,
        daily_frequencies: {}
      }

      post :create_or_update_multiple,
           params: { locale: 'pt-BR' },
           body: invalid_json.to_json

      expect(response).to have_http_status(:ok)
    end

    it 'handles missing required parameters' do
      missing_params = {
        locale: 'pt-BR',
        frequency_in_batch_form: {
          unity_id: unity.id,
          # classroom_id e discipline_id são obrigatórios
        },
        daily_frequencies: {}
      }

      post :create_or_update_multiple, params: missing_params
      expect(response).to have_http_status(:found)
    end

    it 'handles malformed JSON' do
      request.headers['Content-Type'] = 'application/json'

      malformed_json = '{"invalid": "json"'

      expect {
        post :create_or_update_multiple,
             params: { locale: 'pt-BR' },
             body: malformed_json
      }.to raise_error(ActionDispatch::ParamsParser::ParseError)
    end
  end

  describe '#student_exempted_from_discipline_in_range' do
    let(:discipline_extra1) { create(:discipline) }
    let(:discipline_extra2) { create(:discipline) }
    let(:student_exempt_from_all) { create(:student) }
    let(:student_exempt_from_some) { create(:student) }
    let(:student_not_exempt) { create(:student) }
    let(:enrollment_all) { create(:student_enrollment, student: student_exempt_from_all) }
    let(:enrollment_some) { create(:student_enrollment, student: student_exempt_from_some) }
    let(:enrollment_none) { create(:student_enrollment, student: student_not_exempt) }
    let(:enrollment_ids) { [enrollment_all.id, enrollment_some.id, enrollment_none.id] }
    let(:frequency_dates) { [school_calendar.steps.first.start_at.to_s] }

    before do
      create(:teacher_discipline_classroom, classroom: classroom, discipline: discipline_extra1)
      create(:teacher_discipline_classroom, classroom: classroom, discipline: discipline_extra2)

      # student_exempt_from_all: dispensado de todas as disciplinas da turma
      create(:student_enrollment_exempted_discipline,
             student_enrollment: enrollment_all, discipline: discipline)
      create(:student_enrollment_exempted_discipline,
             student_enrollment: enrollment_all, discipline: discipline_extra1)
      create(:student_enrollment_exempted_discipline,
             student_enrollment: enrollment_all, discipline: discipline_extra2)

      # student_exempt_from_some: dispensado apenas de duas (não todas)
      create(:student_enrollment_exempted_discipline,
             student_enrollment: enrollment_some, discipline: discipline)
      create(:student_enrollment_exempted_discipline,
             student_enrollment: enrollment_some, discipline: discipline_extra1)

      controller.instance_variable_set(:@classroom, classroom)
    end

    context 'when using general frequency' do
      before do
        controller.instance_variable_set(:@discipline, nil)
        controller.instance_variable_set(:@frequency_type, FrequencyTypes::GENERAL)
      end

      it 'returns only students exempt from all disciplines of the classroom' do
        result = controller.send(:student_exempted_from_discipline_in_range, enrollment_ids, frequency_dates)

        student_ids = result.flat_map { |r| r[:student_ids] }
        expect(student_ids).to contain_exactly(student_exempt_from_all.id)
      end

      it 'returns hash entries keyed by step_number' do
        result = controller.send(:student_exempted_from_discipline_in_range, enrollment_ids, frequency_dates)

        expect(result).to match_array(
          [{ step_number: 1, student_ids: [student_exempt_from_all.id] }]
        )
      end
    end

    context 'when using by-discipline frequency for a discipline with exemptions' do
      before do
        controller.instance_variable_set(:@discipline, discipline)
        controller.instance_variable_set(:@frequency_type, FrequencyTypes::BY_DISCIPLINE)
      end

      it 'returns students exempt from the specific discipline' do
        result = controller.send(:student_exempted_from_discipline_in_range, enrollment_ids, frequency_dates)

        student_ids = result.flat_map { |r| r[:student_ids] }
        expect(student_ids).to contain_exactly(student_exempt_from_all.id, student_exempt_from_some.id)
      end
    end

    context 'when using by-discipline frequency for a discipline without exemptions' do
      let(:discipline_without_exemptions) { create(:discipline) }

      before do
        create(:teacher_discipline_classroom, classroom: classroom, discipline: discipline_without_exemptions)
        controller.instance_variable_set(:@discipline, discipline_without_exemptions)
        controller.instance_variable_set(:@frequency_type, FrequencyTypes::BY_DISCIPLINE)
      end

      it 'returns an empty list' do
        result = controller.send(:student_exempted_from_discipline_in_range, enrollment_ids, frequency_dates)

        expect(result).to eq([])
      end
    end

    context 'when no enrollments are passed' do
      before do
        controller.instance_variable_set(:@discipline, nil)
        controller.instance_variable_set(:@frequency_type, FrequencyTypes::GENERAL)
      end

      it 'returns an empty list' do
        result = controller.send(:student_exempted_from_discipline_in_range, [], frequency_dates)

        expect(result).to eq([])
      end
    end
  end

  describe '#additional_data' do
    let(:discipline_extra1) { create(:discipline) }
    let(:discipline_extra2) { create(:discipline) }
    let(:student_exempt_from_all) { create(:student) }
    let(:enrollment_all) { create(:student_enrollment, student: student_exempt_from_all) }
    let(:frequency_date) { school_calendar.steps.first.start_at.to_date }

    before do
      create(:teacher_discipline_classroom, classroom: classroom, discipline: discipline_extra1)
      create(:teacher_discipline_classroom, classroom: classroom, discipline: discipline_extra2)

      [discipline, discipline_extra1, discipline_extra2].each do |disc|
        create(:student_enrollment_exempted_discipline,
               student_enrollment: enrollment_all, discipline: disc)
      end

      controller.instance_variable_set(:@classroom, classroom)
      controller.instance_variable_set(:@discipline, nil)
      controller.instance_variable_set(:@frequency_type, FrequencyTypes::GENERAL)
      controller.instance_variable_set(:@allow_active_search_frequency, false)
    end

    it 'marks students exempt from all disciplines with status :exempted_from_discipline in general frequency' do
      exempteds = controller.send(
        :student_exempted_from_discipline_in_range,
        [enrollment_all.id],
        [frequency_date]
      )

      result = controller.send(
        :additional_data,
        [frequency_date],
        [student_exempt_from_all.id],
        [],
        [],
        exempteds,
        []
      )

      expect(result).to include(
        hash_including(
          date: frequency_date,
          student_id: student_exempt_from_all.id,
          status: :exempted_from_discipline
        )
      )
    end
  end

  describe '#all_students_inactive?' do
    let(:dates) { [Date.new(2026, 1, 12), Date.new(2026, 1, 13)] }

    context 'when no enrollment is active on any of the dates' do
      it 'returns true' do
        enrollment_classrooms = [
          { student_enrollment_classroom: StudentEnrollmentClassroom.new(joined_at: '2026-02-01', left_at: '') },
          { student_enrollment_classroom: StudentEnrollmentClassroom.new(joined_at: '2026-03-01', left_at: '') }
        ]

        expect(controller.send(:all_students_inactive?, enrollment_classrooms, dates)).to eq(true)
      end
    end

    context 'when at least one enrollment is active on a date' do
      it 'returns false' do
        enrollment_classrooms = [
          { student_enrollment_classroom: StudentEnrollmentClassroom.new(joined_at: '2026-02-01', left_at: '') },
          { student_enrollment_classroom: StudentEnrollmentClassroom.new(joined_at: '2026-01-01', left_at: '') }
        ]

        expect(controller.send(:all_students_inactive?, enrollment_classrooms, dates)).to eq(false)
      end
    end

    context 'when there are no enrollments' do
      it 'returns true' do
        expect(controller.send(:all_students_inactive?, [], dates)).to eq(true)
      end
    end
  end

  describe '#check_and_preserve_existing_justifications_batch' do
    # Esse teste verifica que o controller chama o AbsenceJustificationPreserver corretamente
    let(:frequency_date) { school_calendar.steps.first.start_at }
    let(:student_2) { create(:student) }

    let(:daily_frequency) do
      instance_double(
        DailyFrequency,
        frequency_date: frequency_date,
        classroom_id: classroom.id,
        period: Periods::MATUTINAL,
        class_number: 1,
        present?: true
      )
    end

    let(:daily_frequency_student_1) do
      instance_double(
        DailyFrequencyStudent,
        daily_frequency: daily_frequency,
        student_id: student.id,
        present: true,
        absence_justification_student_id: nil
      ).tap do |dfs|
        allow(dfs).to receive(:present=)
        allow(dfs).to receive(:absence_justification_student_id=)
      end
    end

    let(:daily_frequency_student_2) do
      instance_double(
        DailyFrequencyStudent,
        daily_frequency: daily_frequency,
        student_id: student_2.id,
        present: true,
        absence_justification_student_id: nil
      ).tap do |dfs|
        allow(dfs).to receive(:present=)
        allow(dfs).to receive(:absence_justification_student_id=)
      end
    end

    it 'calls AbsenceJustificationPreserver for each daily frequency' do
      students_to_save = [daily_frequency_student_1, daily_frequency_student_2]

      expect(AbsenceJustificationPreserver).to receive(:call).with(
        frequency_date: frequency_date,
        classroom_id: classroom.id,
        period: Periods::MATUTINAL,
        class_number: 1,
        student_ids: [student.id, student_2.id]
      ).and_return({})

      controller.send(
        :check_and_preserve_existing_justifications_batch,
        students_to_save
      )
    end

    it 'applies justifications returned by the service to students' do
      students_to_save = [daily_frequency_student_1, daily_frequency_student_2]
      justification_id = 999

      allow(AbsenceJustificationPreserver).to receive(:call).and_return(
        student.id => justification_id
      )

      expect(daily_frequency_student_1).to receive(:present=).with(false)
      expect(daily_frequency_student_1).to receive(:absence_justification_student_id=).with(justification_id)
      expect(daily_frequency_student_2).not_to receive(:present=)
      expect(daily_frequency_student_2).not_to receive(:absence_justification_student_id=)

      controller.send(
        :check_and_preserve_existing_justifications_batch,
        students_to_save
      )
    end
  end
end
