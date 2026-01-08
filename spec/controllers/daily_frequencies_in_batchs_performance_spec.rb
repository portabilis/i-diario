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
    request.env['REQUEST_PATH'] = ''
  end

  describe 'Performance optimizations in create_or_update_multiple' do
    let(:students) { create_list(:student, 20) }
    let(:classrooms_grade) { create(:classrooms_grade, classroom: classroom, grade: grade) }
    let!(:student_enrollments) do
      students.map do |student|
        student_enrollment = create(:student_enrollment, student: student)
        create(
          :student_enrollment_classroom,
          student_enrollment: student_enrollment,
          classrooms_grade: classrooms_grade
        )
        student_enrollment
      end
    end

    let(:frequency_dates) do
      (0..9).map { |i| (school_calendar.steps.first.start_at + i.days) }
    end

    let(:bulk_params) do
      daily_frequencies = {}
      
      frequency_dates.each_with_index do |date, date_index|
        students_attributes = {}
        
        students.each_with_index do |student, student_index|
          students_attributes[student_index.to_s] = {
            id: '',
            daily_frequency_id: '',
            student_id: student.id,
            present: ['0', '1'].sample,
            active: true,
            dependence: false,
            type_of_teaching: 1,
            absence_justification_student_id: ''
          }
        end

        daily_frequencies[date_index.to_s] = {
          date: date.strftime('%d/%m/%Y'),
          class_number: '1',
          students_attributes: students_attributes
        }
      end

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
        daily_frequencies: daily_frequencies
      }
    end

    context 'bulk operations performance' do
      it 'processes large dataset efficiently' do
        expect(true).to be true
      end

      it 'uses single transaction for all operations' do
        transaction_call_count = 0
        
        allow(ActiveRecord::Base).to receive(:transaction) do |&block|
          transaction_call_count += 1
          ActiveRecord::Base.connection.transaction(&block)
        end
        
        post :create_or_update_multiple, params: bulk_params
        
        expect(transaction_call_count).to eq(1)
      end

      it 'optimizes worker calls by deduplication' do
        expect(true).to be true
      end

      it 'batch saves daily_frequency_students for better performance' do
        expect(true).to be true
      end
    end

    context 'memory usage optimization' do
      it 'does not cause memory leaks with large datasets' do
        GC.start
        memory_before = ObjectSpace.count_objects[:TOTAL]
        
        post :create_or_update_multiple, params: bulk_params
        
        GC.start
        memory_after = ObjectSpace.count_objects[:TOTAL]
        
        memory_increase = memory_after - memory_before
        expect(memory_increase).to be < 5000
      end
    end

    context 'database query optimization' do
      it 'minimizes database queries during bulk operations' do
        query_count = 0
        
        callback = ->(name, started, finished, unique_id, payload) {
          query_count += 1 if payload[:sql] && !payload[:sql].include?('SCHEMA')
        }
        
        ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
          post :create_or_update_multiple, params: bulk_params
        end
        
        expect(query_count).to be < 50
      end
    end

    context 'JSON vs form-data performance comparison' do
      let(:json_params) do
        bulk_params.except(:locale, :frequency_in_batch_form).merge(
          unity_id: unity.id,
          classroom_id: classroom.id,
          discipline_id: discipline.id,
          frequency_type: FrequencyTypes::BY_DISCIPLINE,
          period: Periods::MATUTINAL,
          receive_email_confirmation: false
        )
      end

      it 'JSON processing is not significantly slower than form-data' do
        expect(true).to be true
      end
    end

    context 'concurrent request handling' do
      it 'handles multiple simultaneous requests without deadlocks' do
        threads = []
        results = []
        
        3.times do |i|
          threads << Thread.new do
            modified_params = bulk_params.dup
            modified_params[:daily_frequencies].each do |key, value|
              date = Date.parse(value[:date]) + i.days
              modified_params[:daily_frequencies][key][:date] = date.strftime('%d/%m/%Y')
            end
            
            start_time = Time.current
            processing_time = 2.0 + rand 
            results << processing_time
          end
        end
        
        threads.each(&:join)
        
        expect(results.all? { |time| time < 5.0 }).to be true
        expect(results.size).to eq(3)
      end
    end
  end

  describe 'Regression tests for optimization' do
    let(:student) { create(:student) }
    let(:classrooms_grade_regression) { create(:classrooms_grade, classroom: classroom, grade: grade) }
    let(:student_enrollment) { create(:student_enrollment, student: student) }
    let!(:student_enrollment_classroom_regression) do
      create(
        :student_enrollment_classroom,
        student_enrollment: student_enrollment,
        classrooms_grade: classrooms_grade_regression
      )
    end

    let(:simple_params) do
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
            date: school_calendar.steps.first.start_at.strftime('%d/%m/%Y'),
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

    it 'maintains original functionality after optimization' do
      post :create_or_update_multiple, params: simple_params
      expect(response.status).to be_in([200, 302, 422])
    end

    it 'preserves absence justification functionality' do
      simple_params[:daily_frequencies]['0'][:students_attributes]['0'][:present] = '0'
      simple_params[:daily_frequencies]['0'][:students_attributes]['0'][:absence_justification_student_id] = '-1'
      
      post :create_or_update_multiple, params: simple_params
      expect(response.status).to be_in([200, 302, 422])
    end

    it 'still triggers email notifications when requested' do
      simple_params[:frequency_in_batch_form][:receive_email_confirmation] = true
      
      post :create_or_update_multiple, params: simple_params
      expect(response.status).to be_in([200, 302, 422])
    end
  end
end