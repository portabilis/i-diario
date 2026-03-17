require 'spec_helper'

RSpec.describe StudentEnrollmentSynchronizer, type: :service do
  let(:synchronization) { create(:ieducar_api_synchronization) }
  let(:worker_batch) { create(:worker_batch) }
  let(:worker_state) { create(:worker_state, worker_batch: worker_batch) }
  let(:entity_id) { Entity.first.id }
  let(:unity_api_code) { '32' }
  let(:year) { 2025 }

  let(:synchronizer) do
    described_class.new(
      synchronization: synchronization,
      worker_batch: worker_batch,
      worker_state: worker_state,
      entity_id: entity_id,
      year: year,
      unity_api_code: unity_api_code,
      current_years: [year]
    )
  end

  describe '#update_student_enrollments' do
    let(:student_enrollment_data) do
      double(
        'enrollment',
        matricula_id: '12345',
        aluno_id: '54326',
        situacao: 3,
        ativo: 1,
        updated_at: Time.current,
        deleted_at: nil
      )
    end

    context 'when student exists in database' do
      let!(:existing_student) { create(:student, api_code: '54326', name: 'João Silva') }

      it 'processes enrollment with existing student' do
        expect {
          synchronizer.send(:update_student_enrollments, [student_enrollment_data])
        }.to change(StudentEnrollment, :count).by(1)

        enrollment = StudentEnrollment.find_by(api_code: '12345')
        expect(enrollment).to be_present
        expect(enrollment.student_id).to eq(existing_student.id)
        expect(enrollment.student_code).to eq('54326')
      end

      it 'does not call API to fetch student' do
        students_api = instance_double(IeducarApi::Students)
        expect(IeducarApi::Students).not_to receive(:new)

        synchronizer.send(:update_student_enrollments, [student_enrollment_data])
      end
    end

    context 'when student does not exist - partial synchronization' do
      before do
        allow(synchronization).to receive(:full_synchronization?).and_return(false)
      end

      context 'and API returns valid student data' do
        let(:api_response) do
          {
            'id' => 54326,
            'nome' => 'CAMILLY GONÇALVES TEIXEIRA',
            'nome_social' => nil,
            'url_foto_aluno' => nil,
            'data_nascimento' => '2012-12-13',
            'destroyed_at' => nil
          }
        end

        before do
          students_api = instance_double(IeducarApi::Students)
          allow(IeducarApi::Students).to receive(:new).and_return(students_api)
          allow(students_api).to receive(:fetch_by_id).with('54326').and_return(api_response)
        end

        it 'creates student from API data' do
          expect {
            synchronizer.send(:update_student_enrollments, [student_enrollment_data])
          }.to change(Student, :count).by(1)

          student = Student.find_by(api_code: '54326')
          expect(student).to be_present
          expect(student.name).to eq('CAMILLY GONÇALVES TEIXEIRA')
          expect(student.birth_date).to eq(Date.parse('2012-12-13'))
          expect(student.api).to be true
        end

        it 'creates enrollment with the new student' do
          expect {
            synchronizer.send(:update_student_enrollments, [student_enrollment_data])
          }.to change(StudentEnrollment, :count).by(1)

          enrollment = StudentEnrollment.find_by(api_code: '12345')
          expect(enrollment).to be_present
          expect(enrollment.student.api_code).to eq('54326')
        end

        it 'caches the created student' do
          synchronizer.send(:update_student_enrollments, [student_enrollment_data])

          cached_student = synchronizer.instance_variable_get(:@students)
          expect(cached_student).to be_present
          expect(cached_student['54326']).to be_present
          expect(cached_student['54326'].name).to eq('CAMILLY GONÇALVES TEIXEIRA')
        end
      end

      context 'and API returns invalid data' do
        before do
          students_api = instance_double(IeducarApi::Students)
          allow(IeducarApi::Students).to receive(:new).and_return(students_api)
          allow(students_api).to receive(:fetch_by_id).with('54326').and_return(nil)
        end

        it 'does not create student' do
          expect {
            synchronizer.send(:update_student_enrollments, [student_enrollment_data])
          }.not_to change(Student, :count)
        end

        it 'does not create student enrollment' do
          expect {
            synchronizer.send(:update_student_enrollments, [student_enrollment_data])
          }.not_to change(StudentEnrollment, :count)
        end

        it 'discards existing enrollment if present' do
          existing_enrollment = create(:student_enrollment, api_code: '12345')

          synchronizer.send(:update_student_enrollments, [student_enrollment_data])

          existing_enrollment.reload
          expect(existing_enrollment.discarded?).to be true
        end
      end

      context 'and API raises error' do
        before do
          students_api = instance_double(IeducarApi::Students)
          allow(IeducarApi::Students).to receive(:new).and_return(students_api)
          allow(students_api).to receive(:fetch_by_id).with('54326').and_raise(StandardError, 'API Error')
          allow(Rails.logger).to receive(:warn)
        end

        it 'logs warning and continues' do
          expect(Rails.logger).to receive(:warn).with('Failed to fetch student 54326: API Error')

          expect {
            synchronizer.send(:update_student_enrollments, [student_enrollment_data])
          }.not_to raise_error
        end

        it 'does not create student or enrollment' do
          expect {
            synchronizer.send(:update_student_enrollments, [student_enrollment_data])
          }.not_to change(Student, :count)

          expect {
            synchronizer.send(:update_student_enrollments, [student_enrollment_data])
          }.not_to change(StudentEnrollment, :count)
        end
      end
    end

    context 'when student does not exist - full synchronization' do
      before do
        allow(synchronization).to receive(:full_synchronization?).and_return(true)
      end

      it 'does not try to fetch student from API' do
        expect(IeducarApi::Students).not_to receive(:new)

        synchronizer.send(:update_student_enrollments, [student_enrollment_data])
      end

      it 'does not create student or enrollment' do
        expect {
          synchronizer.send(:update_student_enrollments, [student_enrollment_data])
        }.not_to change(Student, :count)

        expect {
          synchronizer.send(:update_student_enrollments, [student_enrollment_data])
        }.not_to change(StudentEnrollment, :count)
      end

      it 'discards existing enrollment if present' do
        existing_enrollment = create(:student_enrollment, api_code: '12345')

        synchronizer.send(:update_student_enrollments, [student_enrollment_data])

        existing_enrollment.reload
        expect(existing_enrollment.discarded?).to be true
      end
    end

    context 'with multiple enrollments for same student' do
      let(:enrollment_1) do
        double(
          'enrollment1',
          matricula_id: '12345',
          aluno_id: '54326',
          situacao: 3,
          ativo: 1,
          updated_at: Time.current,
          deleted_at: nil
        )
      end

      let(:enrollment_2) do
        double(
          'enrollment2',
          matricula_id: '12346',
          aluno_id: '54326',
          situacao: 3,
          ativo: 1,
          updated_at: Time.current,
          deleted_at: nil
        )
      end

      let(:api_response) do
        {
          'id' => 54326,
          'nome' => 'CAMILLY GONÇALVES TEIXEIRA',
          'nome_social' => nil,
          'url_foto_aluno' => nil,
          'data_nascimento' => '2012-12-13',
          'destroyed_at' => nil
        }
      end

      before do
        allow(synchronization).to receive(:full_synchronization?).and_return(false)
      end

      it 'only calls API once for same student' do
        students_api = instance_double(IeducarApi::Students)
        allow(IeducarApi::Students).to receive(:new).and_return(students_api)

        expect(students_api).to receive(:fetch_by_id).with('54326').once.and_return(api_response)

        synchronizer.send(:update_student_enrollments, [enrollment_1, enrollment_2])
      end

      it 'creates one student and two enrollments' do
        students_api = instance_double(IeducarApi::Students)
        allow(IeducarApi::Students).to receive(:new).and_return(students_api)
        allow(students_api).to receive(:fetch_by_id).with('54326').and_return(api_response)

        expect {
          synchronizer.send(:update_student_enrollments, [enrollment_1, enrollment_2])
        }.to change(Student, :count).by(1)
          .and change(StudentEnrollment, :count).by(2)

        student = Student.find_by(api_code: '54326')
        expect(StudentEnrollment.where(student: student).count).to eq(2)
      end
    end

    context 'when student is discarded' do
      let!(:discarded_student) do
        create(:student, api_code: '54326', name: 'João Silva').tap(&:discard)
      end

      it 'discards student enrollment and does not process it' do
        expect {
          synchronizer.send(:update_student_enrollments, [student_enrollment_data])
        }.not_to change(StudentEnrollment, :count)

        existing_enrollment = create(:student_enrollment, api_code: '12345')
        synchronizer.send(:update_student_enrollments, [student_enrollment_data])

        existing_enrollment.reload
        expect(existing_enrollment.discarded?).to be true
      end
    end
  end

  describe '#create_student_from_api_data' do
    let(:valid_api_data) do
      {
        'id' => 54326,
        'nome' => 'CAMILLY GONÇALVES TEIXEIRA',
        'nome_social' => 'CAMILLY',
        'url_foto_aluno' => 'http://example.com/photo.jpg',
        'data_nascimento' => '2012-12-13',
        'destroyed_at' => nil
      }
    end

    context 'with valid data' do
      it 'creates new student with correct attributes' do
        student = synchronizer.send(:create_student_from_api_data, valid_api_data)

        expect(student).to be_persisted
        expect(student.api_code).to eq('54326')
        expect(student.name).to eq('CAMILLY GONÇALVES TEIXEIRA')
        expect(student.social_name).to eq('CAMILLY')
        expect(student.avatar_url).to eq('http://example.com/photo.jpg')
        expect(student.birth_date).to eq(Date.parse('2012-12-13'))
        expect(student.api).to be true
        expect(student.uses_differentiated_exam_rule).to be false
      end

      it 'updates existing student' do
        existing_student = create(:student, api_code: '54326', name: 'Nome Antigo')

        student = synchronizer.send(:create_student_from_api_data, valid_api_data)

        expect(student.id).to eq(existing_student.id)
        expect(student.name).to eq('CAMILLY GONÇALVES TEIXEIRA')
      end
    end

    context 'with data without birth_date' do
      let(:data_without_birth_date) do
        valid_api_data.except('data_nascimento')
      end

      it 'creates student without setting birth_date' do
        student = synchronizer.send(:create_student_from_api_data, data_without_birth_date)

        expect(student).to be_persisted
        expect(student.birth_date).to be_nil
      end
    end

    context 'with blank name' do
      let(:data_with_blank_name) do
        valid_api_data.merge('nome' => '')
      end

      it 'returns nil' do
        student = synchronizer.send(:create_student_from_api_data, data_with_blank_name)
        expect(student).to be_nil
      end
    end

    context 'with destroyed_at present' do
      let(:destroyed_data) do
        valid_api_data.merge('destroyed_at' => '2023-01-01 10:00:00')
      end

      it 'creates student and discards it' do
        student = synchronizer.send(:create_student_from_api_data, destroyed_data)

        expect(student).to be_persisted
        expect(student.discarded?).to be true
      end
    end

    context 'when student has no changes' do
      it 'does not call save' do
        existing_student = create(
          :student,
          api_code: '54326',
          name: 'CAMILLY GONÇALVES TEIXEIRA',
          social_name: 'CAMILLY',
          avatar_url: 'http://example.com/photo.jpg',
          birth_date: Date.parse('2012-12-13'),
          api: true
        )

        expect_any_instance_of(Student).not_to receive(:save!)

        student = synchronizer.send(:create_student_from_api_data, valid_api_data)
        expect(student.id).to eq(existing_student.id)
      end
    end
  end

  describe '#fetch_and_create_missing_student' do
    let(:student_id) { '54326' }
    let(:api_response) do
      {
        'id' => 54326,
        'nome' => 'CAMILLY GONÇALVES TEIXEIRA',
        'data_nascimento' => '2012-12-13',
        'destroyed_at' => nil
      }
    end

    context 'when API call succeeds' do
      before do
        students_api = instance_double(IeducarApi::Students)
        allow(IeducarApi::Students).to receive(:new).and_return(students_api)
        allow(students_api).to receive(:fetch_by_id).with(student_id).and_return(api_response)
      end

      it 'calls API with correct parameters' do
        students_api = instance_double(IeducarApi::Students)
        expect(IeducarApi::Students).to receive(:new)
          .with(synchronization.to_api, synchronization.full_synchronization)
          .and_return(students_api)
        expect(students_api).to receive(:fetch_by_id).with(student_id).and_return(api_response)

        synchronizer.send(:fetch_and_create_missing_student, student_id)
      end

      it 'creates and returns student' do
        student = synchronizer.send(:fetch_and_create_missing_student, student_id)

        expect(student).to be_present
        expect(student).to be_persisted
        expect(student.api_code).to eq(student_id)
      end
    end

    context 'when API returns empty response' do
      before do
        students_api = instance_double(IeducarApi::Students)
        allow(IeducarApi::Students).to receive(:new).and_return(students_api)
        allow(students_api).to receive(:fetch_by_id).with(student_id).and_return(nil)
      end

      it 'returns nil' do
        student = synchronizer.send(:fetch_and_create_missing_student, student_id)
        expect(student).to be_nil
      end
    end

    context 'when API returns response without id' do
      before do
        students_api = instance_double(IeducarApi::Students)
        allow(IeducarApi::Students).to receive(:new).and_return(students_api)
        allow(students_api).to receive(:fetch_by_id).with(student_id).and_return({ 'nome' => 'João' })
      end

      it 'returns nil' do
        student = synchronizer.send(:fetch_and_create_missing_student, student_id)
        expect(student).to be_nil
      end
    end

    context 'when API raises error' do
      before do
        students_api = instance_double(IeducarApi::Students)
        allow(IeducarApi::Students).to receive(:new).and_return(students_api)
        allow(students_api).to receive(:fetch_by_id).with(student_id).and_raise(StandardError, 'Network error')
        allow(Rails.logger).to receive(:warn)
      end

      it 'logs warning and returns nil' do
        expect(Rails.logger).to receive(:warn).with("Failed to fetch student #{student_id}: Network error")

        student = synchronizer.send(:fetch_and_create_missing_student, student_id)
        expect(student).to be_nil
      end
    end
  end
end
