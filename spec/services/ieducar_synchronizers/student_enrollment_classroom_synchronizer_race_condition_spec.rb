require 'rails_helper'

RSpec.describe StudentEnrollmentClassroomSynchronizer do
  describe 'race condition handling' do
    let(:classroom) { create(:classroom) }
    let(:grade) { create(:grade) }
    let!(:classrooms_grade) { create(:classrooms_grade, classroom: classroom, grade: grade) }
    let(:student_enrollment) { create(:student_enrollment) }

    let(:api_response) do
      {
        'enturmacoes' => [
          {
            'id' => 99999,
            'matricula_id' => student_enrollment.api_code,
            'turma_id' => classroom.api_code,
            'serie_id' => grade.api_code,
            'data_entrada' => '2026-02-01',
            'data_saida' => '',
            'updated_at' => '2026-02-18',
            'deleted_at' => nil,
            'sequencial' => 1,
            'sequencial_fechamento' => 1,
            'apresentar_fora_da_data' => false,
            'turno_id' => nil
          }
        ]
      }
    end

    let(:synchronizer) do
      StudentEnrollmentClassroomSynchronizer.new(
        synchronization: create(:ieducar_api_synchronization),
        worker_batch: nil,
        worker_state: nil,
        entity_id: nil,
        year: 2026,
        unity_api_code: nil,
        current_years: [2026]
      )
    end

    before do
      allow_any_instance_of(IeducarApi::StudentEnrollmentClassrooms)
        .to receive(:fetch).and_return(api_response)
    end

    it 'handles race condition when another process inserts the same record between SELECT and INSERT' do
      # Simula o cenário: find_or_initialize_by retorna new_record,
      # mas entre o SELECT e o save!, outro processo insere o mesmo registro
      call_count = 0

      allow(StudentEnrollmentClassroom).to receive(:with_discarded).and_return(StudentEnrollmentClassroom)

      allow(StudentEnrollmentClassroom).to receive(:find_or_initialize_by)
        .with(api_code: 99999)
        .and_wrap_original do |method, *args|
          call_count += 1
          result = method.call(*args)

          # Na primeira chamada, simula outro processo criando o registro
          if call_count == 1 && result.new_record?
            StudentEnrollmentClassroom.create!(
              api_code: 99999,
              student_enrollment: student_enrollment,
              classrooms_grade: classrooms_grade,
              classroom_code: classroom.api_code,
              joined_at: '2026-02-01',
              left_at: '',
              changed_at: '2026-02-18',
              sequence: 1,
              index: 1,
              show_as_inactive_when_not_in_date: false
            )
          end

          result
        end

      # Não deve lançar exceção - o retry deve resolver
      expect { synchronizer.synchronize! }.not_to raise_error

      # Deve existir apenas 1 registro
      expect(StudentEnrollmentClassroom.where(api_code: 99999).count).to eq(1)

      # O retry deve ter sido executado (2 chamadas ao find_or_initialize_by)
      expect(call_count).to eq(2)
    end

    it 'creates record normally when no race condition occurs' do
      allow(StudentEnrollmentClassroom).to receive(:with_discarded).and_return(StudentEnrollmentClassroom)

      expect { synchronizer.synchronize! }.not_to raise_error

      record = StudentEnrollmentClassroom.find_by(api_code: 99999)
      expect(record).to be_present
      expect(record.student_enrollment).to eq(student_enrollment)
      expect(record.classrooms_grade).to eq(classrooms_grade)
      expect(record.joined_at.to_s).to eq('2026-02-01')
    end

    it 'updates existing record without error' do
      existing = create(
        :student_enrollment_classroom,
        api_code: 99999,
        student_enrollment: student_enrollment,
        classrooms_grade: classrooms_grade,
        joined_at: '2026-01-01',
        left_at: ''
      )

      allow(StudentEnrollmentClassroom).to receive(:with_discarded).and_return(StudentEnrollmentClassroom)

      expect { synchronizer.synchronize! }.not_to raise_error

      expect(StudentEnrollmentClassroom.where(api_code: 99999).count).to eq(1)
      expect(existing.reload.joined_at.to_s).to eq('2026-02-01')
    end
  end
end
