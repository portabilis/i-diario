require 'rails_helper'

RSpec.describe ClassroomsSynchronizer, type: :service do
  describe '#should_destroy_old_grades?' do
    let(:synchronization) { create(:ieducar_api_synchronization, full_synchronization: full_synchronization) }
    let(:worker_batch) { create(:worker_batch) }
    let(:worker_state) { create(:worker_state, worker_batch: worker_batch) }
    let(:unity) { create(:unity) }
    let(:entity_id) { Entity.first.id }

    let(:synchronizer) do
      described_class.new(
        synchronization: synchronization,
        worker_batch: worker_batch,
        worker_state: worker_state,
        entity_id: entity_id,
        year: Date.current.year,
        unity_api_code: unity.api_code
      )
    end

    context 'when full_synchronization is true' do
      let(:full_synchronization) { true }

      it 'returns true regardless of classroom updated_at' do
        result = synchronizer.send(:should_destroy_old_grades?, '2020-01-01')

        expect(result).to be true
      end
    end

    context 'when partial synchronization' do
      let(:full_synchronization) { false }

      context 'when @modified_at is blank' do
        before do
          synchronizer.instance_variable_set(:@modified_at, nil)
        end

        it 'returns true (safe fallback)' do
          result = synchronizer.send(:should_destroy_old_grades?, '2020-01-01')

          expect(result).to be true
        end
      end

      context 'when @modified_at is set' do
        let(:modified_at) { Time.zone.parse('2025-12-14 00:00:00') }

        before do
          synchronizer.instance_variable_set(:@modified_at, modified_at)
        end

        # Cenario 1: turma não foi modificada, apenas algumas séries foram
        # Nesse caso, não devemos excluir grades antigas pois a API não retornou todas
        context 'when classroom updated_at is before modified_at' do
          it 'returns false to prevent improper deletion' do
            classroom_updated_at = '2025-12-01 10:00:00'

            result = synchronizer.send(:should_destroy_old_grades?, classroom_updated_at)

            expect(result).to be false
          end
        end

        # Cenario 2: turma foi modificada (ex: série removida intencionalmente)
        # A condição t.updated_at >= modified garante que todas as séries foram retornadas
        context 'when classroom updated_at is equal to modified_at' do
          it 'returns true to allow deletion' do
            classroom_updated_at = '2025-12-14 00:00:00'

            result = synchronizer.send(:should_destroy_old_grades?, classroom_updated_at)

            expect(result).to be true
          end
        end

        context 'when classroom updated_at is after modified_at' do
          it 'returns true to allow deletion' do
            classroom_updated_at = '2025-12-15 10:00:00'

            result = synchronizer.send(:should_destroy_old_grades?, classroom_updated_at)

            expect(result).to be true
          end
        end
      end
    end
  end

  describe '#destroy_old_grades' do
    let(:synchronization) { create(:ieducar_api_synchronization, full_synchronization: false) }
    let(:worker_batch) { create(:worker_batch) }
    let(:worker_state) { create(:worker_state, worker_batch: worker_batch) }
    let(:unity) { create(:unity) }
    let(:entity_id) { Entity.first.id }
    let(:classroom) { create(:classroom, unity: unity) }
    let(:grade_to_keep) { create(:grade) }
    let(:grade_to_remove) { create(:grade) }
    let(:exam_rule) { create(:exam_rule) }

    let(:synchronizer) do
      described_class.new(
        synchronization: synchronization,
        worker_batch: worker_batch,
        worker_state: worker_state,
        entity_id: entity_id,
        year: Date.current.year,
        unity_api_code: unity.api_code
      )
    end

    before do
      create(:classrooms_grade, classroom: classroom, grade: grade_to_keep, exam_rule: exam_rule)
      create(:classrooms_grade, classroom: classroom, grade: grade_to_remove, exam_rule: exam_rule)
    end

    context 'when should_destroy_old_grades? returns false' do
      before do
        synchronizer.instance_variable_set(:@modified_at, Time.zone.parse('2025-12-14 00:00:00'))
      end

      it 'does not destroy any ClassroomsGrade' do
        classroom_updated_at = '2025-12-01 10:00:00'

        expect {
          synchronizer.send(:destroy_old_grades, [grade_to_keep.id], classroom.classrooms_grades, classroom_updated_at)
        }.not_to change(ClassroomsGrade, :count)
      end
    end

    context 'when should_destroy_old_grades? returns true' do
      before do
        synchronizer.instance_variable_set(:@modified_at, Time.zone.parse('2025-12-14 00:00:00'))
      end

      it 'destroys ClassroomsGrade not in the grades_ids list' do
        classroom_updated_at = '2025-12-15 10:00:00'

        expect {
          synchronizer.send(:destroy_old_grades, [grade_to_keep.id], classroom.classrooms_grades, classroom_updated_at)
        }.to change(ClassroomsGrade, :count).by(-1)

        expect(ClassroomsGrade.exists?(grade_id: grade_to_keep.id)).to be true
        expect(ClassroomsGrade.exists?(grade_id: grade_to_remove.id)).to be false
      end
    end

    context 'when full_synchronization is true' do
      let(:synchronization) { create(:ieducar_api_synchronization, full_synchronization: true) }

      it 'always destroys ClassroomsGrade regardless of dates' do
        synchronizer.instance_variable_set(:@modified_at, Time.zone.parse('2025-12-14 00:00:00'))
        classroom_updated_at = '2020-01-01 00:00:00'

        expect {
          synchronizer.send(:destroy_old_grades, [grade_to_keep.id], classroom.classrooms_grades, classroom_updated_at)
        }.to change(ClassroomsGrade, :count).by(-1)

        expect(ClassroomsGrade.exists?(grade_id: grade_to_keep.id)).to be true
        expect(ClassroomsGrade.exists?(grade_id: grade_to_remove.id)).to be false
      end
    end
  end

  describe '#update_classrooms' do
    let(:synchronization) { create(:ieducar_api_synchronization, full_synchronization: true) }
    let(:worker_batch) { create(:worker_batch) }
    let(:worker_state) { create(:worker_state, worker_batch: worker_batch) }
    let(:unity) { create(:unity, api_code: '111') }
    let(:entity_id) { Entity.first.id }

    let(:synchronizer) do
      described_class.new(
        synchronization: synchronization,
        worker_batch: worker_batch,
        worker_state: worker_state,
        entity_id: entity_id,
        year: Date.current.year,
        unity_api_code: unity.api_code
      )
    end

    it 'stores the classroom regent api code (ref_cod_regente)' do
      unity
      create(:grade, api_code: '22')
      create(:exam_rule, api_code: '33')

      payload = HashDecorator.new(
        [{
          'id' => '999', 'nome' => 'Turma Sincronizada', 'ano' => Date.current.year,
          'escola_id' => '111', 'turno_id' => 1, 'max_aluno' => 30,
          'ref_cod_regente' => '777',
          'series_regras' => [{ 'serie_id' => '22', 'regra_avaliacao_id' => '33' }],
          'updated_at' => Date.current.to_s, 'deleted_at' => nil
        }]
      )

      synchronizer.send(:update_classrooms, payload)

      expect(Classroom.find_by(api_code: '999').regent_api_code).to eq('777')
    end
  end

  describe '#destroy_orphan_descriptive_exams' do
    let(:unity) { create(:unity) }
    let(:entity_id) { (Entity.first || create(:entity)).id }
    let(:classroom) { create(:classroom, :with_classroom_semester_steps) }

    let(:synchronizer) do
      described_class.new(
        synchronization: create(:ieducar_api_synchronization, full_synchronization: false),
        worker_batch: nil,
        worker_state: nil,
        entity_id: entity_id,
        year: Date.current.year,
        unity_api_code: unity.api_code
      )
    end

    def add_rule(target, opinion_type, differentiated_opinion_type: nil)
      differentiated = create(:exam_rule, opinion_type: differentiated_opinion_type) if differentiated_opinion_type
      create(:classrooms_grade, classroom: target, grade: create(:grade),
                                exam_rule: create(:exam_rule, opinion_type: opinion_type,
                                                              differentiated_exam_rule: differentiated))
    end

    def add_exam(target, opinion_type)
      create(:descriptive_exam, classroom: target, opinion_type: opinion_type, optional_teacher: true)
    end

    context 'with valid and orphaned descriptive exams in the same classroom' do
      before { add_rule(classroom, OpinionTypes::BY_YEAR) }

      let!(:valid_exam) { add_exam(classroom, OpinionTypes::BY_YEAR) }
      let!(:orphan) { add_exam(classroom, OpinionTypes::BY_YEAR_AND_DISCIPLINE) }

      it 'destroys only the orphans and keeps the valid ones in the same run' do
        synchronizer.send(:destroy_orphan_descriptive_exams, classroom)

        expect(DescriptiveExam.where(classroom_id: classroom.id)).to contain_exactly(valid_exam)
      end

      it 'records the deletion in the audit trail with the sync actor' do
        synchronizer.send(:destroy_orphan_descriptive_exams, classroom)

        audit = Audited::Audit.where(auditable_type: 'DescriptiveExam', action: 'destroy').last
        expect(audit.username).to eq('descriptive_exams_opinion_type_sync')
      end
    end

    context 'with an orphan in another classroom' do
      before { add_rule(classroom, OpinionTypes::BY_YEAR) }

      let!(:orphan_here) { add_exam(classroom, OpinionTypes::BY_YEAR_AND_DISCIPLINE) }
      let(:other_classroom) { create(:classroom, :with_classroom_semester_steps) }
      let!(:other_orphan) { add_exam(other_classroom, OpinionTypes::BY_YEAR_AND_DISCIPLINE) }

      it 'destroys only the target classroom, without touching another classroom' do
        synchronizer.send(:destroy_orphan_descriptive_exams, classroom)

        expect(DescriptiveExam.exists?(orphan_here.id)).to be false
        expect(DescriptiveExam.exists?(other_orphan.id)).to be true
      end
    end

    context 'with a multi-grade classroom whose rules have different opinion_types' do
      before do
        add_rule(classroom, OpinionTypes::BY_YEAR)                # grade A: 6
        add_rule(classroom, OpinionTypes::BY_YEAR_AND_DISCIPLINE) # grade B: 5
      end

      let!(:exam_a) { add_exam(classroom, OpinionTypes::BY_YEAR) }
      let!(:exam_b) { add_exam(classroom, OpinionTypes::BY_YEAR_AND_DISCIPLINE) }

      it 'keeps the valid descriptive exams of any grade (union of opinion_types)' do
        synchronizer.send(:destroy_orphan_descriptive_exams, classroom)

        expect(DescriptiveExam.where(classroom_id: classroom.id)).to contain_exactly(exam_a, exam_b)
      end
    end

    context 'with a regular rule plus a differentiated (inclusive) rule' do
      before { add_rule(classroom, OpinionTypes::BY_YEAR, differentiated_opinion_type: OpinionTypes::BY_YEAR_AND_DISCIPLINE) }

      let!(:regular_exam) { add_exam(classroom, OpinionTypes::BY_YEAR) }
      let!(:inclusive_exam) { add_exam(classroom, OpinionTypes::BY_YEAR_AND_DISCIPLINE) }

      it 'keeps both the regular and the inclusive descriptive exams' do
        synchronizer.send(:destroy_orphan_descriptive_exams, classroom)

        expect(DescriptiveExam.where(classroom_id: classroom.id)).to contain_exactly(regular_exam, inclusive_exam)
      end
    end

    context 'when the orphan has students with filled descriptive exams' do
      before { add_rule(classroom, OpinionTypes::BY_YEAR) }

      let!(:orphan) { add_exam(classroom, OpinionTypes::BY_YEAR_AND_DISCIPLINE) }
      let!(:student) { create(:descriptive_exam_student, descriptive_exam: orphan) }

      it 'also destroys the students (cascade) of the orphaned exam' do
        synchronizer.send(:destroy_orphan_descriptive_exams, classroom)

        expect(DescriptiveExamStudent.exists?(student.id)).to be false
      end
    end

    context 'when the classroom has no rule that allows descriptive exams (e.g. DONT_USE)' do
      before do
        create(:classrooms_grade, classroom: classroom,
                                  exam_rule: create(:exam_rule, opinion_type: OpinionTypes::DONT_USE))
      end

      let!(:exam) { add_exam(classroom, OpinionTypes::BY_YEAR) }

      it 'does not destroy anything (load-bearing guard against deleting all exams)' do
        synchronizer.send(:destroy_orphan_descriptive_exams, classroom)

        expect(DescriptiveExam.exists?(exam.id)).to be true
      end
    end
  end

  describe '#update_classrooms reconciling orphaned descriptive exams on rule change' do
    let(:unity) { create(:unity, api_code: '111') }
    let(:grade) { create(:grade, api_code: '22') }
    let!(:old_rule) { create(:exam_rule, api_code: '33', opinion_type: OpinionTypes::BY_YEAR) }
    let!(:new_rule) { create(:exam_rule, api_code: '44', opinion_type: OpinionTypes::BY_YEAR_AND_DISCIPLINE) }
    let!(:classroom) { create(:classroom, :with_classroom_semester_steps, api_code: '999', unity: unity) }
    let!(:classrooms_grade) { create(:classrooms_grade, classroom: classroom, grade: grade, exam_rule: old_rule) }
    let!(:orphan) do
      create(:descriptive_exam, classroom: classroom, opinion_type: OpinionTypes::BY_YEAR, optional_teacher: true)
    end
    let!(:kept) do
      create(:descriptive_exam, classroom: classroom, opinion_type: OpinionTypes::BY_YEAR_AND_DISCIPLINE,
                                optional_teacher: true)
    end

    let(:synchronizer) do
      described_class.new(
        synchronization: create(:ieducar_api_synchronization, full_synchronization: true),
        worker_batch: nil,
        worker_state: nil,
        entity_id: (Entity.first || create(:entity)).id,
        year: Date.current.year,
        unity_api_code: unity.api_code
      )
    end

    def payload_pointing_to(regra_avaliacao_id)
      HashDecorator.new(
        [{
          'id' => '999', 'nome' => classroom.description, 'ano' => Date.current.year,
          'escola_id' => '111', 'turno_id' => 1, 'max_aluno' => 30, 'ref_cod_regente' => nil,
          'series_regras' => [{ 'serie_id' => '22', 'regra_avaliacao_id' => regra_avaliacao_id }],
          'updated_at' => Date.current.to_s, 'deleted_at' => nil
        }]
      )
    end

    it 'destroys the orphaned exam and keeps the one that still matches the new rule' do
      synchronizer.send(:update_classrooms, payload_pointing_to('44')) # BY_YEAR -> BY_YEAR_AND_DISCIPLINE

      expect(DescriptiveExam.exists?(orphan.id)).to be false
      expect(DescriptiveExam.exists?(kept.id)).to be true
    end

    it 'does not touch the exams when the grade does not change rule' do
      synchronizer.send(:update_classrooms, payload_pointing_to('33')) # keeps BY_YEAR

      expect(DescriptiveExam.exists?(orphan.id)).to be true
      expect(DescriptiveExam.exists?(kept.id)).to be true
    end
  end

  describe '#update_classrooms keeping the grade link in sync with the classroom' do
    let(:unity) { create(:unity, api_code: '111') }
    let(:grade) { create(:grade, api_code: '22') }
    let!(:exam_rule) { create(:exam_rule, api_code: '33') }
    let!(:classroom) { create(:classroom, api_code: '999', unity: unity, period: Periods::MATUTINAL) }
    let!(:classrooms_grade) do
      create(:classrooms_grade, classroom: classroom, grade: grade, exam_rule: exam_rule)
    end

    let(:synchronizer) do
      described_class.new(
        synchronization: create(:ieducar_api_synchronization, full_synchronization: true),
        worker_batch: nil,
        worker_state: nil,
        entity_id: Entity.first.id,
        year: Date.current.year,
        unity_api_code: unity.api_code
      )
    end

    def payload(deleted_at, series_regras = [{ 'serie_id' => '22', 'regra_avaliacao_id' => '33' }])
      HashDecorator.new(
        [{
          'id' => '999', 'nome' => classroom.description, 'ano' => Date.current.year,
          'escola_id' => '111', 'turno_id' => 1, 'max_aluno' => 30, 'ref_cod_regente' => nil,
          'series_regras' => series_regras,
          'updated_at' => Date.current.to_s, 'deleted_at' => deleted_at
        }]
      )
    end

    context 'when the classroom comes back active in i-Educar' do
      # Reproduz o estado deixado pelo descarte: turma e vínculo descartados juntos.
      before { classroom.discard }

      it 'reactivates the classroom and its grade link' do
        expect(ClassroomsGrade.with_discarded.find(classrooms_grade.id)).to be_discarded

        synchronizer.send(:update_classrooms, payload(nil))

        expect(Classroom.with_discarded.find(classroom.id)).to be_kept
        expect(ClassroomsGrade.with_discarded.find(classrooms_grade.id)).to be_kept
      end

      it 'lists the classroom again when filtering by grade' do
        expect(Classroom.by_grade(grade.id)).to be_empty

        synchronizer.send(:update_classrooms, payload(nil))

        expect(Classroom.by_grade(grade.id).pluck(:id)).to eq([classroom.id])
      end
    end

    context 'when the classroom that comes back has a filled lessons board' do
      let!(:lessons_board) do
        create(:lessons_board, :full_lessons_board, classrooms_grade: classrooms_grade)
      end

      def kept_weekdays_count
        LessonsBoardLessonWeekday.joins(:lessons_board_lesson)
                                 .where(lessons_board_lessons: { lessons_board_id: lessons_board.id })
                                 .count
      end

      before { classroom.discard }

      it 'brings the whole lessons board back, down to the weekdays' do
        expect(kept_weekdays_count).to eq(0)

        synchronizer.send(:update_classrooms, payload(nil))

        expect(LessonsBoard.with_discarded.find(lessons_board.id)).to be_kept
        expect(kept_weekdays_count).to eq(20)
      end
    end

    context 'when the classroom has more than one grade' do
      let(:other_grade) { create(:grade, api_code: '44') }
      let!(:other_classrooms_grade) do
        create(:classrooms_grade, classroom: classroom, grade: other_grade, exam_rule: exam_rule)
      end

      before { classroom.discard }

      it 'reactivates every grade link returned by the API' do
        synchronizer.send(:update_classrooms, payload(nil, [
                                                       { 'serie_id' => '22', 'regra_avaliacao_id' => '33' },
                                                       { 'serie_id' => '44', 'regra_avaliacao_id' => '33' }
                                                     ]))

        expect(ClassroomsGrade.where(classroom_id: classroom.id).pluck(:id))
          .to contain_exactly(classrooms_grade.id, other_classrooms_grade.id)
      end
    end

    context 'when the classroom is excluded in i-Educar' do
      it 'discards the classroom and its grade link' do
        synchronizer.send(:update_classrooms, payload('2025-12-14 00:00:00'))

        expect(Classroom.with_discarded.find(classroom.id)).to be_discarded
        expect(ClassroomsGrade.with_discarded.find(classrooms_grade.id)).to be_discarded
      end
    end
  end
end
