require 'rails_helper'

RSpec.describe DailyFrequencyHelper, type: :helper do
  let!(:school_calendar) { create(:school_calendar, :with_one_step) }
  let!(:discipline) { create(:discipline) }
  let!(:teacher) { create(:teacher) }
  let!(:classroom) {
    create(
      :classroom,
      :with_classroom_trimester_steps,
      school_calendar: school_calendar,
      unity: school_calendar.unity
    )
  }
  let!(:teacher_discipline_classroom) {
    create(
      :teacher_discipline_classroom,
      classroom: classroom,
      discipline: discipline,
      teacher: teacher,
      )
  }

  let!(:daily_frequencies) {
    create_list(
      :daily_frequency,
      1,
      classroom: classroom,
      discipline: discipline
    )
  }

  describe '#params_for_print_month' do
    context '#when params are correct' do
      it 'returns hash with correct params' do
        daily_frequency = daily_frequencies[0]
        result = {
            unity_id: school_calendar.unity.id,
            classroom_id: classroom.id,
            discipline_id: discipline.id,
            class_numbers: '1,2',
            start_at: l(daily_frequency.frequency_date.at_beginning_of_month),
            end_at: l(daily_frequency.frequency_date.end_of_month),
            school_calendar_year: classroom.year,
            current_teacher_id: teacher.id,
            period: daily_frequency.period
        }
        helper.instance_variable_set(:@number_of_classes, 2)
        allow(helper).to receive(:current_teacher).and_return(teacher)
        expect(helper.params_for_print_month(daily_frequencies)).to eq(result)
      end
    end

  end

  describe '#params_for_print_step' do
    context '#when params are correct' do
      it 'returns hash with correct params' do
        daily_frequency = daily_frequencies[0]
        result = {
          unity_id: school_calendar.unity.id,
          classroom_id: classroom.id,
          discipline_id: discipline.id,
          class_numbers: '1,2',
          start_at: l(daily_frequency.frequency_date.at_beginning_of_month),
          end_at: l(daily_frequency.frequency_date.end_of_month),
          school_calendar_year: classroom.year,
          current_teacher_id: teacher.id,
          period: daily_frequency.period
        }
        helper.instance_variable_set(:@number_of_classes, 2)
        allow(helper).to receive(:current_teacher).and_return(teacher)
        expect(helper.params_for_print_month(daily_frequencies)).to eq(result)
      end
    end
  end

  describe '#frequency_student_name_class' do
    context '#when student has dependence' do
      it 'returns string with correct params' do
        dependence = true
        active = true
        exempted_from_discipline = true
        in_active_search = true
        result = 'multiline dependence-student'
        response = helper.frequency_student_name_class(dependence, active, exempted_from_discipline, in_active_search)
        expect(response).to eq(result)
      end
    end

    context '#when student is inactive' do
      it 'returns string with correct params' do
        dependence = true
        active = false
        exempted_from_discipline = true
        in_active_search = true
        result = 'multiline inactive-student'
        response = helper.frequency_student_name_class(dependence, active, exempted_from_discipline, in_active_search)
        expect(response).to eq(result)
      end
    end

    context '#when student is exempted' do
      it 'returns string with correct params' do
        dependence = false
        active = true
        exempted_from_discipline = true
        in_active_search = true
        result = 'multiline exempted-student-from-discipline'
        response = helper.frequency_student_name_class(dependence, active, exempted_from_discipline, in_active_search)
        expect(response).to eq(result)
      end
    end

    context '#when student is in active search' do
      it 'returns string with correct params' do
        dependence = false
        active = true
        exempted_from_discipline = false
        in_active_search = true
        result = 'multiline in-active-search'
        response = helper.frequency_student_name_class(dependence, active, exempted_from_discipline, in_active_search)
        expect(response).to eq(result)
      end
    end
  end

  describe '#frequency_student_name' do
    let(:student) { create(:student) }
    context '#when student has dependence' do
      it 'returns string with correct params' do
        dependence = true
        active = true
        exempted_from_discipline = true
        in_active_search = true
        result = '*' + student.name
        response = helper.frequency_student_name(student, dependence, active, exempted_from_discipline, in_active_search)
        expect(response).to eq(result)
      end
    end

    context '#when student is inactive' do
      it 'returns string with correct params' do
        dependence = true
        active = false
        exempted_from_discipline = true
        in_active_search = true
        result = '***' + student.name
        response = helper.frequency_student_name(student, dependence, active, exempted_from_discipline, in_active_search)
        expect(response).to eq(result)
      end
    end

    context '#when student is exempted' do
      it 'returns string with correct params' do
        dependence = false
        active = true
        exempted_from_discipline = true
        in_active_search = true
        result = '****' + student.name
        response = helper.frequency_student_name(student, dependence, active, exempted_from_discipline, in_active_search)
        expect(response).to eq(result)
      end
    end

    context '#when student is in active search' do
      it 'returns string with correct params' do
        dependence = false
        active = true
        exempted_from_discipline = false
        in_active_search = true
        result = '*****' + student.name
        response = helper.frequency_student_name(student, dependence, active, exempted_from_discipline, in_active_search)
        expect(response).to eq(result)
      end
    end
  end
end
