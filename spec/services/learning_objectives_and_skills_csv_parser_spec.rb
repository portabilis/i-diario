require 'rails_helper'

RSpec.describe LearningObjectivesAndSkillsCsvParser do
  let(:fixtures_path) { Rails.root.join('spec', 'fixtures', 'csv') }

  describe '#parse' do
    context 'when CSV is Ensino Fundamental format' do
      let(:file) { File.open(fixtures_path.join('bncc_ensino_fundamental.csv')) }
      let(:parser) { described_class.new(file, step: 'elementary_school').parse }

      it 'uses the provided step' do
        expect(parser.step).to eq('elementary_school')
      end

      it 'parses all valid data rows skipping headers' do
        expect(parser.records.size).to eq(3)
      end

      it 'has no parsing errors' do
        expect(parser.errors).to be_empty
      end

      it 'normalizes discipline names with missing accents' do
        # "Lingua Portuguesa" -> "portuguese_language"
        record = parser.records.find { |r| r[:code] == 'EF01CO01' }

        expect(record[:discipline]).to eq('portuguese_language')
      end

      it 'normalizes discipline names without accents' do
        # "Matematica" -> "mathematics"
        record = parser.records.find { |r| r[:code] == 'EF01CO02' }

        expect(record[:discipline]).to eq('mathematics')
      end

      it 'normalizes discipline names with extra punctuation' do
        # "Educação Fisica." -> "physical_education"
        record = parser.records.find { |r| r[:code] == 'EF02CO01' }

        expect(record[:discipline]).to eq('physical_education')
      end

      it 'maps grades correctly' do
        record = parser.records.find { |r| r[:code] == 'EF01CO01' }

        expect(record[:grades]).to eq(['first_year'])
      end

      it 'sets step from parameter on all records' do
        parser.records.each do |record|
          expect(record[:step]).to eq('elementary_school')
        end
      end

      it 'preserves thematic_unit' do
        record = parser.records.find { |r| r[:code] == 'EF01CO01' }

        expect(record[:thematic_unit]).to eq('Organização do objetos')
      end

      it 'preserves description' do
        record = parser.records.find { |r| r[:code] == 'EF01CO01' }

        expect(record[:description]).to eq('Organizar objetos físicos ou digitais.')
      end

      it 'sets field_of_experience to nil for elementary school' do
        parser.records.each do |record|
          expect(record[:field_of_experience]).to be_nil
        end
      end
    end

    context 'when CSV is Educação Infantil format' do
      let(:file) { File.open(fixtures_path.join('bncc_educacao_infantil.csv')) }
      let(:parser) { described_class.new(file, step: 'child_school').parse }

      it 'uses the provided step' do
        expect(parser.step).to eq('child_school')
      end

      it 'parses all valid data rows' do
        expect(parser.records.size).to eq(3)
      end

      it 'maps experience fields correctly' do
        record = parser.records.find { |r| r[:code] == 'EI03CO01' }

        expect(record[:field_of_experience]).to eq('the_me_the_other_and_the_us')
      end

      it 'normalizes experience field with typo (missing s)' do
        # "Traços, sons, cores e forma" -> strokes_sounds_colors_and_shapes
        record = parser.records.find { |r| r[:code] == 'EI03CO03' }

        expect(record[:field_of_experience]).to eq('strokes_sounds_colors_and_shapes')
      end

      it 'maps grades correctly for preschool' do
        record = parser.records.first

        expect(record[:grades]).to eq(['preschool'])
      end

      it 'sets discipline to nil for child school' do
        parser.records.each do |record|
          expect(record[:discipline]).to be_nil
        end
      end
    end

    context 'when step is EJA with Ensino Fundamental CSV format' do
      let(:csv_content) do
        <<~CSV
          Código*,Componente Curricular*,Etapa*,Série*,Unidade Temática,Objetivo/habilidade*
          EJA01,Matemática,Educação para jovens e adultos,1º ano EJA,Números,Resolver problemas com adição.
        CSV
      end
      let(:file) { Tempfile.new(['eja_test', '.csv']).tap { |f| f.write(csv_content); f.rewind } }
      let(:parser) { described_class.new(file, step: 'adult_and_youth_education').parse }

      it 'uses the provided step' do
        expect(parser.step).to eq('adult_and_youth_education')
      end

      it 'parses EJA records with 6 column format' do
        expect(parser.records.size).to eq(1)
        expect(parser.errors).to be_empty
      end

      it 'sets step as adult_and_youth_education on records' do
        expect(parser.records.first[:step]).to eq('adult_and_youth_education')
      end

      it 'maps EJA grades correctly' do
        expect(parser.records.first[:grades]).to eq(['eja_first_year'])
      end
    end

    context 'when CSV step diverges from selected step (same column format)' do
      let(:csv_content) do
        <<~CSV
          Código*,Componente Curricular*,Etapa*,Série*,Unidade Temática,Objetivo/habilidade*
          EF01LP01,Língua Portuguesa,Ensino Fundamental,1º ano,Leitura,Descrição válida.
          EF02MA01,Matemática,Ensino Fundamental,2º ano,Números,Outra descrição.
        CSV
      end
      let(:file) { Tempfile.new(['test', '.csv']).tap { |f| f.write(csv_content); f.rewind } }
      let(:parser) { described_class.new(file, step: 'adult_and_youth_education').parse }

      it 'reports a single file-level error instead of per-row errors' do
        expect(parser.errors.size).to eq(1)
        expect(parser.errors.first[:field]).to eq('arquivo')
        expect(parser.errors.first[:message]).to include("CSV é da etapa 'Ensino Fundamental'")
        expect(parser.errors.first[:message]).to include("'Educação para Jovens e Adultos'")
      end

      it 'does not parse any records' do
        expect(parser.records).to be_empty
      end
    end

    context 'when CSV step diverges from selected step (single wrong step)' do
      let(:csv_content) do
        <<~CSV
          Código*,Componente Curricular*,Etapa*,Série*,Unidade Temática,Objetivo/habilidade*
          EF01CO01,Arte,Educação Infantil,1º ano,Unidade 1,Descrição válida.
        CSV
      end
      let(:file) { Tempfile.new(['test', '.csv']).tap { |f| f.write(csv_content); f.rewind } }
      let(:parser) { described_class.new(file, step: 'elementary_school').parse }

      it 'reports a single file-level error' do
        expect(parser.errors.size).to eq(1)
        expect(parser.errors.first[:field]).to eq('arquivo')
        expect(parser.errors.first[:message]).to include("CSV é da etapa 'Educação Infantil'")
        expect(parser.errors.first[:message]).to include("'Ensino Fundamental'")
      end

      it 'does not include the record' do
        expect(parser.records).to be_empty
      end
    end

    context 'when CSV has mixed steps (some correct, some wrong)' do
      let(:csv_content) do
        <<~CSV
          Código*,Componente Curricular*,Etapa*,Série*,Unidade Temática,Objetivo/habilidade*
          EF01CO01,Arte,Ensino Fundamental,1º ano,Unidade 1,Descrição válida.
          EF02CO01,Matemática,Educação para jovens e adultos,2º ano,Unidade 2,Outra descrição.
        CSV
      end
      let(:file) { Tempfile.new(['test', '.csv']).tap { |f| f.write(csv_content); f.rewind } }
      let(:parser) { described_class.new(file, step: 'elementary_school').parse }

      it 'reports only the step errors (not discipline/grade errors)' do
        expect(parser.errors.size).to eq(1)
        expect(parser.errors.first[:field]).to eq('Etapa')
        expect(parser.errors.first[:message]).to include('diverge da etapa selecionada')
      end

      it 'does not parse any records' do
        expect(parser.records).to be_empty
      end
    end

    context 'when CSV has unrecognized step value' do
      let(:csv_content) do
        <<~CSV
          Código*,Componente Curricular*,Etapa*,Série*,Unidade Temática,Objetivo/habilidade*
          EF01CO01,Arte,Ensino Médio,1º ano,Unidade 1,Descrição válida.
        CSV
      end
      let(:file) { Tempfile.new(['test', '.csv']).tap { |f| f.write(csv_content); f.rewind } }
      let(:parser) { described_class.new(file, step: 'elementary_school').parse }

      it 'reports the unrecognized step error' do
        expect(parser.errors.size).to eq(1)
        expect(parser.errors.first[:field]).to eq('Etapa')
        expect(parser.errors.first[:original_value]).to eq('Ensino Médio')
      end

      it 'does not parse any records' do
        expect(parser.records).to be_empty
      end
    end

    context 'when CSV step matches selected step' do
      let(:csv_content) do
        <<~CSV
          Código*,Componente Curricular*,Etapa*,Série*,Unidade Temática,Objetivo/habilidade*
          EF01CO01,Arte,Ensino Fundamental,1º ano,Unidade 1,Descrição válida.
        CSV
      end
      let(:file) { Tempfile.new(['test', '.csv']).tap { |f| f.write(csv_content); f.rewind } }
      let(:parser) { described_class.new(file, step: 'elementary_school').parse }

      it 'has no step errors' do
        step_errors = parser.errors.select { |e| e[:field] == 'Etapa' }

        expect(step_errors).to be_empty
      end

      it 'includes the record' do
        expect(parser.records.size).to eq(1)
      end
    end

    context 'when CSV step column is blank' do
      let(:csv_content) do
        <<~CSV
          Código*,Componente Curricular*,Etapa*,Série*,Unidade Temática,Objetivo/habilidade*
          EF01CO01,Arte,,1º ano,Unidade 1,Descrição válida.
        CSV
      end
      let(:file) { Tempfile.new(['test', '.csv']).tap { |f| f.write(csv_content); f.rewind } }
      let(:parser) { described_class.new(file, step: 'elementary_school').parse }

      it 'does not report step error' do
        step_errors = parser.errors.select { |e| e[:field] == 'Etapa' }

        expect(step_errors).to be_empty
      end

      it 'includes the record using the selected step' do
        expect(parser.records.size).to eq(1)
        expect(parser.records.first[:step]).to eq('elementary_school')
      end
    end

    context 'when CSV has multiple grades in a single cell' do
      let(:csv_content) do
        <<~CSV
          Código*,Componente Curricular*,Etapa*,Série*,Unidade Temática,Objetivo/habilidade*
          EF01CO01,Arte,Ensino Fundamental,"1º ano, 2º ano, 3º ano",Unidade 1,Descrição válida.
        CSV
      end
      let(:file) { Tempfile.new(['test', '.csv']).tap { |f| f.write(csv_content); f.rewind } }
      let(:parser) { described_class.new(file, step: 'elementary_school').parse }

      it 'parses all grades from the comma-separated value' do
        expect(parser.records.first[:grades]).to eq(%w[first_year second_year third_year])
      end

      it 'creates a single record with multiple grades' do
        expect(parser.records.size).to eq(1)
        expect(parser.errors).to be_empty
      end
    end

    context 'when CSV has unknown discipline' do
      let(:file) { File.open(fixtures_path.join('bncc_invalid_discipline.csv')) }
      let(:parser) { described_class.new(file, step: 'elementary_school').parse }

      it 'reports error for unknown discipline' do
        expect(parser.errors.size).to eq(1)
        expect(parser.errors.first[:field]).to eq('Componente Curricular')
        expect(parser.errors.first[:original_value]).to eq('Disciplina Inexistente')
      end

      it 'does not include the invalid record' do
        expect(parser.records).to be_empty
      end
    end

    context 'when CSV has empty rows at the end' do
      let(:csv_content) do
        <<~CSV
          Importante:,,,,,,
          Ensino Fundamental,,,,,
          Código*,Componente Curricular*,Etapa*,Série*,Unidade Temática,Objetivo/habilidade*
          EF01CO01,Arte,Ensino Fundamental,1º ano,Unidade 1,Descrição válida.
          ,,,,,
          ,,,,,
        CSV
      end
      let(:file) { Tempfile.new(['test', '.csv']).tap { |f| f.write(csv_content); f.rewind } }
      let(:parser) { described_class.new(file, step: 'elementary_school').parse }

      it 'skips empty rows' do
        expect(parser.records.size).to eq(1)
        expect(parser.errors).to be_empty
      end
    end

    context 'when grade does not belong to selected step' do
      let(:csv_content) do
        <<~CSV
          Código*,Campo de Experiência*,Etapa*,Série*,Objetivo/habilidade*
          EI01CO01,O eu o outro e o nós,Educação Infantil,1º ano,Descrição válida.
        CSV
      end
      let(:file) { Tempfile.new(['test', '.csv']).tap { |f| f.write(csv_content); f.rewind } }
      let(:parser) { described_class.new(file, step: 'child_school').parse }

      it 'reports grade incompatibility error' do
        grade_error = parser.errors.find { |e| e[:field] == 'Série' }

        expect(grade_error).to be_present
        expect(grade_error[:message]).to include('não pertence à etapa selecionada')
        expect(grade_error[:original_value]).to eq('1º ano')
      end

      it 'does not include the record' do
        expect(parser.records).to be_empty
      end
    end

    context 'when elementary grade is used with EJA step' do
      let(:csv_content) do
        <<~CSV
          Código*,Componente Curricular*,Etapa*,Série*,Unidade Temática,Objetivo/habilidade*
          EF01CO01,Arte,Educação para jovens e adultos,1º ano,Unidade 1,Descrição válida.
        CSV
      end
      let(:file) { Tempfile.new(['test', '.csv']).tap { |f| f.write(csv_content); f.rewind } }
      let(:parser) { described_class.new(file, step: 'adult_and_youth_education').parse }

      it 'reports grade incompatibility error' do
        grade_error = parser.errors.find { |e| e[:field] == 'Série' }

        expect(grade_error).to be_present
        expect(grade_error[:message]).to include('não pertence à etapa selecionada')
      end

      it 'does not include the record' do
        expect(parser.records).to be_empty
      end
    end

    context 'when EJA grade is used with elementary step' do
      let(:csv_content) do
        <<~CSV
          Código*,Componente Curricular*,Etapa*,Série*,Unidade Temática,Objetivo/habilidade*
          EF01CO01,Arte,Ensino Fundamental,1º ano EJA,Unidade 1,Descrição válida.
        CSV
      end
      let(:file) { Tempfile.new(['test', '.csv']).tap { |f| f.write(csv_content); f.rewind } }
      let(:parser) { described_class.new(file, step: 'elementary_school').parse }

      it 'reports grade incompatibility error' do
        grade_error = parser.errors.find { |e| e[:field] == 'Série' }

        expect(grade_error).to be_present
        expect(grade_error[:original_value]).to eq('1º ano EJA')
      end

      it 'does not include the record' do
        expect(parser.records).to be_empty
      end
    end

    context 'when CSV has a trailing comma on the header (empty column at the end)' do
      let(:file) { File.open(fixtures_path.join('bncc_educacao_infantil_trailing_comma.csv')) }
      let(:parser) { described_class.new(file, step: 'child_school').parse }

      it 'ignores the trailing empty column and does not report format mismatch' do
        format_error = parser.errors.find { |e| e[:field] == 'arquivo' }

        expect(format_error).to be_nil
      end

      it 'parses all valid data rows' do
        expect(parser.records.size).to eq(2)
      end
    end

    context 'when format_mismatch error is reported' do
      let(:file) { File.open(fixtures_path.join('bncc_educacao_infantil.csv')) }
      let(:parser) { described_class.new(file, step: 'elementary_school').parse }

      it 'includes the detected header in the error message' do
        expect(parser.errors.first[:message]).to include('Cabeçalho detectado:')
        expect(parser.errors.first[:message]).to include('Código*')
        expect(parser.errors.first[:message]).to include('Objetivo/habilidade*')
      end
    end

    context 'when child_school step is selected but CSV has 6 columns (elementary format)' do
      let(:file) { File.open(fixtures_path.join('bncc_ensino_fundamental.csv')) }
      let(:parser) { described_class.new(file, step: 'child_school').parse }

      it 'reports a single format mismatch error' do
        expect(parser.errors.size).to eq(1)
        expect(parser.errors.first[:field]).to eq('arquivo')
        expect(parser.errors.first[:message]).to include('não corresponde à etapa selecionada')
      end

      it 'does not parse any records' do
        expect(parser.records).to be_empty
      end
    end

    context 'when elementary step is selected but CSV has 5 columns (child_school format)' do
      let(:file) { File.open(fixtures_path.join('bncc_educacao_infantil.csv')) }
      let(:parser) { described_class.new(file, step: 'elementary_school').parse }

      it 'reports a single format mismatch error' do
        expect(parser.errors.size).to eq(1)
        expect(parser.errors.first[:field]).to eq('arquivo')
        expect(parser.errors.first[:message]).to include('não corresponde à etapa selecionada')
      end

      it 'does not parse any records' do
        expect(parser.records).to be_empty
      end
    end

    context 'when EJA step is selected but CSV has 5 columns (child_school format)' do
      let(:file) { File.open(fixtures_path.join('bncc_educacao_infantil.csv')) }
      let(:parser) { described_class.new(file, step: 'adult_and_youth_education').parse }

      it 'reports a single format mismatch error' do
        expect(parser.errors.size).to eq(1)
        expect(parser.errors.first[:message]).to include("'Educação para Jovens e Adultos'")
        expect(parser.errors.first[:message]).to include('5 colunas')
      end

      it 'does not parse any records' do
        expect(parser.records).to be_empty
      end
    end

    context 'when error messages include field context' do
      let(:file) { File.open(fixtures_path.join('bncc_invalid_discipline.csv')) }
      let(:parser) { described_class.new(file, step: 'elementary_school').parse }

      it 'includes field name and step in error message' do
        error = parser.errors.find { |e| e[:field] == 'Componente Curricular' }

        expect(error[:message]).to include("Componente Curricular: 'Disciplina Inexistente'")
        expect(error[:message]).to include("'Ensino Fundamental'")
      end
    end

    context 'when code is blank' do
      let(:csv_content) do
        <<~CSV
          Código*,Componente Curricular*,Etapa*,Série*,Unidade Temática,Objetivo/habilidade*
          ,Arte,Ensino Fundamental,1º ano,Unidade 1,Descrição válida.
        CSV
      end
      let(:file) { Tempfile.new(['test', '.csv']).tap { |f| f.write(csv_content); f.rewind } }
      let(:parser) { described_class.new(file, step: 'elementary_school').parse }

      it 'reports blank code error' do
        error = parser.errors.find { |e| e[:field] == 'Código' }

        expect(error).to be_present
        expect(error[:message]).to include('não pode ficar em branco')
      end

      it 'does not include the record' do
        expect(parser.records).to be_empty
      end
    end

    context 'when CSV has duplicate codes' do
      let(:csv_content) do
        <<~CSV
          Código*,Componente Curricular*,Etapa*,Série*,Unidade Temática,Objetivo/habilidade*
          EF01CO01,Arte,Ensino Fundamental,1º ano,Unidade 1,Primeira descrição.
          EF01CO01,Matemática,Ensino Fundamental,2º ano,Unidade 2,Segunda descrição.
        CSV
      end
      let(:file) { Tempfile.new(['test', '.csv']).tap { |f| f.write(csv_content); f.rewind } }
      let(:parser) { described_class.new(file, step: 'elementary_school').parse }

      it 'reports duplicate code error for the second occurrence' do
        error = parser.errors.find { |e| e[:field] == 'Código' }

        expect(error).to be_present
        expect(error[:original_value]).to eq('EF01CO01')
        expect(error[:message]).to include('duplicado')
      end

      it 'keeps only the first occurrence' do
        expect(parser.records.size).to eq(1)
        expect(parser.records.first[:description]).to eq('Primeira descrição.')
      end
    end

    context 'when experience field is blank (child school)' do
      let(:csv_content) do
        <<~CSV
          Código*,Campo de Experiência*,Etapa*,Série*,Objetivo/habilidade*
          EI01CO01,,Educação Infantil,Pré-escola - 4 a 5 anos,Descrição válida.
        CSV
      end
      let(:file) { Tempfile.new(['test', '.csv']).tap { |f| f.write(csv_content); f.rewind } }
      let(:parser) { described_class.new(file, step: 'child_school').parse }

      it 'reports blank experience field error' do
        error = parser.errors.find { |e| e[:field] == 'Campo de Experiência' }

        expect(error).to be_present
        expect(error[:message]).to include('não pode ficar em branco')
      end

      it 'does not include the record' do
        expect(parser.records).to be_empty
      end
    end

    context 'when discipline is blank (elementary school)' do
      let(:csv_content) do
        <<~CSV
          Código*,Componente Curricular*,Etapa*,Série*,Unidade Temática,Objetivo/habilidade*
          EF01CO01,,Ensino Fundamental,1º ano,Unidade 1,Descrição válida.
        CSV
      end
      let(:file) { Tempfile.new(['test', '.csv']).tap { |f| f.write(csv_content); f.rewind } }
      let(:parser) { described_class.new(file, step: 'elementary_school').parse }

      it 'reports blank discipline error' do
        error = parser.errors.find { |e| e[:field] == 'Componente Curricular' }

        expect(error).to be_present
        expect(error[:message]).to include('não pode ficar em branco')
      end

      it 'does not include the record' do
        expect(parser.records).to be_empty
      end
    end

    context 'when grade is blank' do
      let(:csv_content) do
        <<~CSV
          Código*,Componente Curricular*,Etapa*,Série*,Unidade Temática,Objetivo/habilidade*
          EF01CO01,Arte,Ensino Fundamental,,Unidade 1,Descrição válida.
        CSV
      end
      let(:file) { Tempfile.new(['test', '.csv']).tap { |f| f.write(csv_content); f.rewind } }
      let(:parser) { described_class.new(file, step: 'elementary_school').parse }

      it 'reports blank grade error' do
        error = parser.errors.find { |e| e[:field] == 'Série' }

        expect(error).to be_present
        expect(error[:message]).to include('não pode ficar em branco')
      end

      it 'does not include the record' do
        expect(parser.records).to be_empty
      end
    end

    context 'when description is blank' do
      let(:csv_content) do
        <<~CSV
          Código*,Componente Curricular*,Etapa*,Série*,Unidade Temática,Objetivo/habilidade*
          EF01CO01,Arte,Ensino Fundamental,1º ano,Unidade 1,
        CSV
      end
      let(:file) { Tempfile.new(['test', '.csv']).tap { |f| f.write(csv_content); f.rewind } }
      let(:parser) { described_class.new(file, step: 'elementary_school').parse }

      it 'reports blank description error' do
        error = parser.errors.find { |e| e[:field] == 'Objetivo/habilidade' }

        expect(error).to be_present
        expect(error[:message]).to include('não pode ficar em branco')
      end

      it 'does not include the record' do
        expect(parser.records).to be_empty
      end
    end
  end

  describe 'normalize method' do
    let(:parser) { described_class.new(Tempfile.new('test'), step: 'elementary_school') }

    it 'removes accents' do
      expect(parser.send(:normalize, 'Língua Portuguesa')).to eq('lingua portuguesa')
    end

    it 'removes punctuation' do
      expect(parser.send(:normalize, 'Educação Fisica.')).to eq('educacao fisica')
    end

    it 'strips and squishes whitespace' do
      expect(parser.send(:normalize, '  Ensino   Fundamental  ')).to eq('ensino fundamental')
    end

    it 'handles ordinal characters' do
      expect(parser.send(:normalize, '1º ano')).to eq('1o ano')
      expect(parser.send(:normalize, '2ª série')).to eq('2a serie')
    end
  end
end
