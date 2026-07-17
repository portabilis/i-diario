require 'rails_helper'

RSpec.describe AvaliationRecoveryDiaryRecordsController, type: :controller do
  describe '#reuse_existing_student_ids' do
    let(:recovery_diary_record) do
      create(:recovery_diary_record, :with_teacher_discipline_classroom, :with_students)
    end
    let(:persisted_student) { recovery_diary_record.students.first }

    before do
      controller.instance_variable_set(
        :@avaliation_recovery_diary_record,
        instance_double(AvaliationRecoveryDiaryRecord, recovery_diary_record: recovery_diary_record)
      )
    end

    def students_attributes_from(result)
      result['recovery_diary_record_attributes']['students_attributes']
    end

    context 'when a persisted student is sent without id' do
      let(:params_hash) do
        {
          'recovery_diary_record_attributes' => {
            'students_attributes' => [
              { 'student_id' => persisted_student.student_id.to_s, 'score' => '8.0' }
            ]
          }
        }
      end

      it 'reuses the persisted recovery_diary_record_student id (update instead of insert)' do
        result = controller.send(:reuse_existing_student_ids, params_hash)

        expect(students_attributes_from(result).first['id']).to eq(persisted_student.id)
      end
    end

    context 'when the same student has duplicate persisted rows' do
      let!(:duplicate_row) do
        create(
          :recovery_diary_record_student,
          recovery_diary_record: recovery_diary_record,
          student: persisted_student.student
        )
      end

      before { recovery_diary_record.students.reload }

      let(:params_hash) do
        {
          'recovery_diary_record_attributes' => {
            'students_attributes' => [
              { 'student_id' => persisted_student.student_id.to_s, 'score' => '8.0' }
            ]
          }
        }
      end

      it 'reuses the most recent existing row (highest id)' do
        result = controller.send(:reuse_existing_student_ids, params_hash)

        expect(students_attributes_from(result).first['id']).to eq(duplicate_row.id)
      end
    end

    context 'when the student is genuinely new (no existing row)' do
      let(:new_student) { create(:student) }
      let(:params_hash) do
        {
          'recovery_diary_record_attributes' => {
            'students_attributes' => [
              { 'student_id' => new_student.id.to_s, 'score' => '6.0' }
            ]
          }
        }
      end

      it 'does not set an id (keeps it as an insert)' do
        result = controller.send(:reuse_existing_student_ids, params_hash)

        expect(students_attributes_from(result).first['id']).to be_nil
      end
    end

    context 'when the student already carries an id' do
      let(:params_hash) do
        {
          'recovery_diary_record_attributes' => {
            'students_attributes' => [
              { 'id' => persisted_student.id, 'student_id' => persisted_student.student_id.to_s, 'score' => '8.0' }
            ]
          }
        }
      end

      it 'keeps the provided id untouched' do
        result = controller.send(:reuse_existing_student_ids, params_hash)

        expect(students_attributes_from(result).first['id']).to eq(persisted_student.id)
      end
    end

    context 'when a row without id is marked for _destroy' do
      let(:params_hash) do
        {
          'recovery_diary_record_attributes' => {
            'students_attributes' => [
              { 'student_id' => persisted_student.student_id.to_s, '_destroy' => 'true' }
            ]
          }
        }
      end

      it 'does not inject an id (avoids turning it into a destroy of an existing row)' do
        result = controller.send(:reuse_existing_student_ids, params_hash)

        expect(students_attributes_from(result).first['id']).to be_nil
      end
    end

    context 'when there are no students to reconcile' do
      it 'returns the hash unchanged for a blank students list' do
        params_hash = { 'recovery_diary_record_attributes' => { 'students_attributes' => [] } }

        expect(controller.send(:reuse_existing_student_ids, params_hash)).to eq(params_hash)
      end

      it 'returns the hash unchanged when the recovery_diary_record_attributes key is missing' do
        expect(controller.send(:reuse_existing_student_ids, {})).to eq({})
      end
    end
  end

  describe '#update reconciliation on save' do
    let(:recovery_diary_record) do
      create(:recovery_diary_record, :with_teacher_discipline_classroom, :with_students)
    end
    let(:persisted_student) { recovery_diary_record.students.first }

    before do
      controller.instance_variable_set(
        :@avaliation_recovery_diary_record,
        instance_double(AvaliationRecoveryDiaryRecord, recovery_diary_record: recovery_diary_record)
      )
    end

    # Regressão-alvo: um aluno reenviado SEM id (form manipulado/forjado) deve
    # atualizar a linha existente, não inserir uma duplicata.
    it 'updates the existing recovery student instead of inserting a duplicate' do
      params_hash = {
        'recovery_diary_record_attributes' => {
          'students_attributes' => [
            { 'student_id' => persisted_student.student_id.to_s, 'score' => '9.0' }
          ]
        }
      }

      reconciled = controller.send(:reuse_existing_student_ids, params_hash)
      students_attributes = reconciled['recovery_diary_record_attributes']['students_attributes']

      expect { recovery_diary_record.update!(students_attributes: students_attributes) }
        .not_to(change { recovery_diary_record.reload.students.count })
    end
  end
end
