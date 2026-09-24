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

      # duplicate_row tem id maior; força a linha mais antiga (persisted_student) a
      # ter o maior updated_at para provar que a reconciliação usa updated_at (a
      # última nota lançada, validada contra a auditoria) e não o id.
      before do
        persisted_student.update_column(:updated_at, 1.hour.from_now)
        recovery_diary_record.students.reload
      end

      let(:params_hash) do
        {
          'recovery_diary_record_attributes' => {
            'students_attributes' => [
              { 'student_id' => persisted_student.student_id.to_s, 'score' => '8.0' }
            ]
          }
        }
      end

      it 'reuses the most recently updated row (highest updated_at), not the highest id' do
        result = controller.send(:reuse_existing_student_ids, params_hash)

        expect(students_attributes_from(result).first['id']).to eq(persisted_student.id)
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

    context 'when the same student has a row with id and another without id' do
      let(:params_hash) do
        {
          'recovery_diary_record_attributes' => {
            'students_attributes' => [
              { 'id' => persisted_student.id, 'student_id' => persisted_student.student_id.to_s, 'score' => '7.0' },
              { 'student_id' => persisted_student.student_id.to_s, 'score' => '2.0' }
            ]
          }
        }
      end

      before { allow(Honeybadger).to receive(:notify) }

      it 'does not let the id-less row claim the id already carried by another row' do
        result = controller.send(:reuse_existing_student_ids, params_hash)
        rows = students_attributes_from(result)

        expect(rows.first['id']).to eq(persisted_student.id)
        expect(rows.second['id']).to be_nil
        expect(rows.second['_destroy']).to eq('1')
      end
    end

    context 'when two rows without id target the same persisted student' do
      before { allow(Honeybadger).to receive(:notify) }

      let(:params_hash) do
        {
          'recovery_diary_record_attributes' => {
            'students_attributes' => [
              { 'student_id' => persisted_student.student_id.to_s, 'score' => '8.0' },
              { 'student_id' => persisted_student.student_id.to_s, 'score' => '3.0' }
            ]
          }
        }
      end

      it 'reuses the id for the first row and marks the excess row for destruction' do
        result = controller.send(:reuse_existing_student_ids, params_hash)
        rows = students_attributes_from(result)

        expect(rows.first['id']).to eq(persisted_student.id)
        expect(rows.first['_destroy']).to be_nil
        expect(rows.second['id']).to be_nil
        expect(rows.second['_destroy']).to eq('1')
      end

      it 'notifies Honeybadger with forensic context for the neutralized row' do
        controller.send(:reuse_existing_student_ids, params_hash)

        expect(Honeybadger).to have_received(:notify).with(
          instance_of(String),
          hash_including(
            context: hash_including(
              student_id: persisted_student.student_id,
              reused_recovery_diary_record_student_id: persisted_student.id
            )
          )
        )
      end
    end

    context "when a row without id carries the literal string 'false' in _destroy" do
      let(:params_hash) do
        {
          'recovery_diary_record_attributes' => {
            'students_attributes' => [
              { 'student_id' => persisted_student.student_id.to_s, 'score' => '8.0', '_destroy' => 'false' }
            ]
          }
        }
      end

      it 'treats the row as active and reuses the persisted id' do
        result = controller.send(:reuse_existing_student_ids, params_hash)

        expect(students_attributes_from(result).first['id']).to eq(persisted_student.id)
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
      allow(Honeybadger).to receive(:notify)
      # A trava de score do model (discard_score_change_for_inactive_student) só
      # persiste a nota de alunos enturmados na recorded_at. Aqui o foco é a
      # reconciliação de id no save, então consideramos o aluno enturmado.
      allow_any_instance_of(RecoveryDiaryRecordStudent)
        .to receive(:student_enrolled_on_recorded_at?).and_return(true)
    end

    # Regressão-alvo: um aluno reenviado SEM id (form manipulado/forjado) deve
    # atualizar a linha existente (com a nota), não inserir uma duplicata.
    it 'updates the existing recovery student row (with its score) instead of inserting a duplicate' do
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

      expect(persisted_student.reload.score).to eq(9.0)
    end

    # Cobre o encadeamento real dos dois reorganizadores de params
    # (list_students_by_active -> reuse_existing_student_ids -> save), incluindo o
    # handoff de shape (Hash de índices -> Array) entre eles.
    it 'reconciles the params shape end-to-end and updates the existing row' do
      params_hash = {
        'recovery_diary_record_attributes' => {
          'students_attributes' => {
            '0' => { 'student_id' => persisted_student.student_id.to_s, 'score' => '7.5' }
          }
        }
      }

      reorganized = controller.send(:list_students_by_active, params_hash)
      reconciled = controller.send(:reuse_existing_student_ids, reorganized)
      students_attributes = reconciled['recovery_diary_record_attributes']['students_attributes']

      expect { recovery_diary_record.update!(students_attributes: students_attributes) }
        .not_to(change { recovery_diary_record.reload.students.count })

      expect(persisted_student.reload.score).to eq(7.5)
    end

    # Caso residual (CRITICAL): duas linhas sem id para o mesmo aluno não podem
    # inserir uma duplicata — a excedente é marcada para exclusão e a nota da
    # primeira linha atualiza a linha existente.
    it 'does not insert a duplicate when two id-less rows target the same student' do
      params_hash = {
        'recovery_diary_record_attributes' => {
          'students_attributes' => [
            { 'student_id' => persisted_student.student_id.to_s, 'score' => '9.0' },
            { 'student_id' => persisted_student.student_id.to_s, 'score' => '3.0' }
          ]
        }
      }

      reconciled = controller.send(:reuse_existing_student_ids, params_hash)
      students_attributes = reconciled['recovery_diary_record_attributes']['students_attributes']

      expect { recovery_diary_record.update!(students_attributes: students_attributes) }
        .not_to(change { recovery_diary_record.reload.students.count })

      expect(persisted_student.reload.score).to eq(9.0)
    end
  end
end
