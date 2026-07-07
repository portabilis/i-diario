require 'rails_helper'

RSpec.describe LearningObjectivesAndSkillsCsvImporter do
  describe '#import' do
    let(:step) { 'elementary_school' }

    let(:records) do
      [
        {
          code: 'EF01LP01',
          discipline: 'portuguese_language',
          step: step,
          grades: ['first_year'],
          thematic_unit: 'Unidade 1',
          description: 'Objetivo 1'
        },
        {
          code: 'EF01LP02',
          discipline: 'mathematics',
          step: step,
          grades: ['first_year'],
          thematic_unit: 'Unidade 2',
          description: 'Objetivo 2'
        }
      ]
    end

    context 'with add_new mode' do
      let(:modes_by_grade) { { 'first_year' => 'add_new' } }

      let(:importer) do
        described_class.new(records: records, step: step, modes_by_grade: modes_by_grade)
      end

      it 'creates new records' do
        expect { importer.import }.to change(LearningObjectivesAndSkill, :count).by(2)
      end

      it 'returns true on success' do
        expect(importer.import).to eq(true)
      end

      it 'reports imported count' do
        importer.import

        expect(importer.imported_count).to eq(2)
      end

      it 'does not remove any records' do
        importer.import

        expect(importer.removed_count).to eq(0)
      end

      it 'does not remove existing records of other grades' do
        create(:learning_objectives_and_skill,
               code: 'EF02LP01',
               step: step,
               grades: ['second_year'])

        importer.import

        expect(LearningObjectivesAndSkill.find_by(code: 'EF02LP01')).to be_present
      end
    end

    context 'with replace mode' do
      let(:modes_by_grade) { { 'first_year' => 'replace' } }

      let(:importer) do
        described_class.new(records: records, step: step, modes_by_grade: modes_by_grade)
      end

      it 'removes existing records for that step+grade before importing' do
        create(:learning_objectives_and_skill,
               code: 'EF01OLD1',
               step: step,
               grades: ['first_year'])
        create(:learning_objectives_and_skill,
               code: 'EF01OLD2',
               step: step,
               grades: ['first_year'])

        importer.import

        expect(LearningObjectivesAndSkill.where(code: %w[EF01OLD1 EF01OLD2])).to be_empty
      end

      it 'keeps records of other grades intact' do
        create(:learning_objectives_and_skill,
               code: 'EF02LP01',
               step: step,
               grades: ['second_year'])

        importer.import

        expect(LearningObjectivesAndSkill.find_by(code: 'EF02LP01')).to be_present
      end

      it 'creates new records from CSV' do
        create(:learning_objectives_and_skill,
               code: 'EF01OLD1',
               step: step,
               grades: ['first_year'])

        importer.import

        expect(LearningObjectivesAndSkill.where(code: %w[EF01LP01 EF01LP02]).count).to eq(2)
      end

      it 'reports removed count' do
        create(:learning_objectives_and_skill,
               code: 'EF01OLD1',
               step: step,
               grades: ['first_year'])

        importer.import

        expect(importer.removed_count).to eq(1)
      end
    end

    context 'with mixed modes across grades' do
      let(:records_mixed) do
        records + [
          {
            code: 'EF02LP01',
            discipline: 'art',
            step: step,
            grades: ['second_year'],
            description: 'Objetivo 3'
          }
        ]
      end

      let(:modes_by_grade) do
        { 'first_year' => 'add_new', 'second_year' => 'replace' }
      end

      let(:importer) do
        described_class.new(records: records_mixed, step: step, modes_by_grade: modes_by_grade)
      end

      it 'only removes records for grades with replace mode' do
        create(:learning_objectives_and_skill,
               code: 'EF02OLD1',
               step: step,
               grades: ['second_year'])

        importer.import

        expect(LearningObjectivesAndSkill.find_by(code: 'EF02OLD1')).to be_nil
      end

      it 'creates new records for all grades' do
        importer.import

        expect(importer.imported_count).to eq(3)
      end
    end

    context 'with replace mode on records shared across grades' do
      let(:step) { 'child_school' }
      let(:modes_by_grade) { { 'preschool' => 'replace' } }

      let(:records) do
        [
          {
            code: 'EI03CO01',
            field_of_experience: 'the_me_the_other_and_the_us',
            step: step,
            grades: ['preschool'],
            description: 'Novo objetivo pré-escola'
          }
        ]
      end

      let(:importer) do
        described_class.new(records: records, step: step, modes_by_grade: modes_by_grade)
      end

      it 'removes only the replaced grade from records shared with other grades' do
        # Registro pertence a creche E pré-escola
        shared_record = create(:learning_objectives_and_skill,
                               code: 'EI02EO01',
                               step: step,
                               grades: %w[nursery_2 preschool])

        importer.import

        shared_record.reload
        expect(shared_record.grades).to eq(['nursery_2'])
      end

      it 'deletes records that belong only to the replaced grade' do
        # Registro pertence apenas à pré-escola
        exclusive_record = create(:learning_objectives_and_skill,
                                  code: 'EI03EO01',
                                  step: step,
                                  grades: ['preschool'])

        importer.import

        expect(LearningObjectivesAndSkill.find_by(code: 'EI03EO01')).to be_nil
      end

      it 'does not touch records of grades not being replaced' do
        # Registro pertence apenas à creche
        other_record = create(:learning_objectives_and_skill,
                              code: 'EI01EO01',
                              step: step,
                              grades: ['nursery_1'])

        importer.import

        other_record.reload
        expect(other_record.grades).to eq(['nursery_1'])
      end

      it 'counts each affected record in removed_count' do
        create(:learning_objectives_and_skill,
               code: 'EI02EO01',
               step: step,
               grades: %w[nursery_2 preschool])
        create(:learning_objectives_and_skill,
               code: 'EI03EO01',
               step: step,
               grades: ['preschool'])

        importer.import

        expect(importer.removed_count).to eq(2)
      end
    end

    context 'when a record fails validation' do
      let(:invalid_records) do
        [
          {
            code: 'EF01LP01',
            discipline: 'portuguese_language',
            step: step,
            grades: ['first_year'],
            description: 'Valid objective'
          },
          {
            code: 'EF01LP02',
            discipline: 'mathematics',
            step: step,
            grades: ['first_year'],
            description: nil
          }
        ]
      end

      let(:modes_by_grade) { { 'first_year' => 'add_new' } }

      let(:importer) do
        described_class.new(records: invalid_records, step: step, modes_by_grade: modes_by_grade)
      end

      it 'rolls back all changes' do
        expect { importer.import }.not_to change(LearningObjectivesAndSkill, :count)
      end

      it 'returns false' do
        expect(importer.import).to eq(false)
      end

      it 'reports errors' do
        importer.import

        expect(importer.errors.size).to eq(1)
        expect(importer.errors.first[:code]).to eq('EF01LP02')
      end
    end
  end
end
