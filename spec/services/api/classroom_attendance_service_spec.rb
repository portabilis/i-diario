require 'rails_helper'

RSpec.describe Api::ClassroomAttendanceService do
  let!(:classrooms) { create_list(:classroom, 3, year: '2024') }
  let!(:start_at) { '2024-02-02'}
  let!(:end_at) { '2024-12-12'}
  let!(:year) { '2024'}

  context 'when params are correct' do
    let!(:params_classrooms) do
      {
        "0" => classrooms.first.api_code,
        "1" => classrooms.second.api_code,
        "2" => classrooms.last.api_code
      }
    end
    let!(:classroom_api_code) { classrooms[0].api_code }
    let!(:classroom_name) { classrooms[0].description }
    let!(:classroom_1_api_code) { classrooms[1].api_code }
    let!(:classroom_1_name) { classrooms[1].description }
    let!(:classroom_2_api_code) { classrooms[2].api_code }
    let!(:classroom_2_name) { classrooms[2].description }

    it 'returns an array of hashes' do
      service = described_class.call(params_classrooms, start_at, end_at, year)

      return_array = [
        { classroom_id: classroom_api_code, classroom_name: classroom_name, classroom_max_students: nil, grades: [],
          :attendance_and_enrollments => nil },
        { classroom_id: classroom_1_api_code, classroom_name: classroom_1_name, classroom_max_students: nil, grades: [],
          :attendance_and_enrollments => nil },
        { classroom_id: classroom_2_api_code, classroom_name: classroom_2_name, classroom_max_students: nil, grades: [],
          :attendance_and_enrollments => nil }
      ]

      expect(service).to match_array(return_array)
    end

    # it 'deve retornar todas as frequencias presentes de todos os alunos enturmados' do
    #   student_enrollment_classroom = create(:student_enrollment_classroom, classroom: list_classrooms[0])
    #   student = student_enrollment_classroom.student
    #   daily_frequency = create(:daily_frequency, classroom: list_classrooms[0], frequency_date: '2024-02-02')
    #   daily_frequency.students << student

    #   service = described_class.call(unity.id, start_at,)
    # end
  end
end
