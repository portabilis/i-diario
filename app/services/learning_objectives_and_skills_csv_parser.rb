# frozen_string_literal: true

class LearningObjectivesAndSkillsCsvParser
  include LearningObjectivesAndSkillsCsvMappings

  attr_reader :records, :errors, :step

  HEADER_MARKERS = ['código', 'codigo'].freeze
  VALID_STEPS = %w[child_school elementary_school adult_and_youth_education].freeze
  MAX_FILE_SIZE = 3.megabytes

  def initialize(file, step:)
    @file = file
    @step = step
    @records = []
    @errors = []
  end

  def parse
    rows = read_csv
    return self if @errors.any?

    header_index = find_header_index(rows)

    unless header_index
      @errors << { row: 0, field: 'arquivo', original_value: '',
                   message: t('header_not_found') }
      return self
    end

    header_row = rows[header_index]
    return self unless validate_csv_format(header_row)

    data_rows = rows[(header_index + 1)..]
    return self unless validate_data_rows_present(data_rows)
    return self unless validate_csv_step(data_rows, header_index + 1)

    parse_data_rows(data_rows, header_index + 1)
    self
  end

  private

  def read_csv
    file_path = @file.respond_to?(:path) ? @file.path : @file.to_s

    if File.size(file_path) > MAX_FILE_SIZE
      @errors << { row: 0, field: 'arquivo', original_value: '',
                   message: t('file_too_large') }
      return []
    end

    raw = File.binread(file_path)
    content = encode_to_utf8(raw)
    CSV.parse(content, col_sep: ',', skip_blanks: true)
  rescue CSV::MalformedCSVError => e
    @errors << { row: 0, field: 'arquivo', original_value: '',
                 message: t('malformed_csv', details: e.message) }
    []
  end

  def encode_to_utf8(content)
    content.force_encoding('UTF-8')
    return content if content.valid_encoding?

    content.force_encoding('ISO-8859-1')
    content.encode('UTF-8')
  rescue Encoding::UndefinedConversionError
    content.force_encoding('UTF-8')
    content
  end

  def find_header_index(rows)
    rows.index do |row|
      first_cell = row[0]&.strip&.downcase
      first_cell && HEADER_MARKERS.any? { |marker| first_cell.start_with?(marker) }
    end
  end

  STEP_LABELS = {
    'child_school' => 'Educação Infantil',
    'elementary_school' => 'Ensino Fundamental',
    'adult_and_youth_education' => 'Educação para Jovens e Adultos'
  }.freeze

  # Valida se o número de colunas do CSV é compatível com a etapa selecionada.
  # Educação Infantil usa 5 colunas, Ensino Fundamental/EJA usam 6 colunas.
  # Colunas vazias à direita são ignoradas para tolerar vírgulas extras no final da linha.
  def validate_csv_format(header_row)
    trimmed_header = trim_trailing_blanks(header_row)
    col_count = trimmed_header.size
    expected_cols = child_school? ? 5 : 6

    return true if col_count == expected_cols

    @errors << {
      row: 0, field: 'arquivo', original_value: '',
      message: t('format_mismatch',
                 selected_step: step_label,
                 col_count: col_count,
                 expected_cols: expected_cols,
                 header: trimmed_header.join(', '))
    }
    false
  end

  def trim_trailing_blanks(row)
    trimmed = row.dup
    trimmed.pop while trimmed.any? && trimmed.last.to_s.strip.empty?
    trimmed
  end

  # Garante que o CSV tenha pelo menos uma linha de dados além do cabeçalho.
  # Linhas totalmente vazias são desconsideradas.
  def validate_data_rows_present(data_rows)
    return true if data_rows.any? { |row| row.any? { |cell| cell.to_s.strip.present? } }

    @errors << { row: 0, field: 'arquivo', original_value: '',
                 message: t('empty_file') }
    false
  end

  # Valida a coluna de etapa de TODAS as linhas de dados antes de validar as demais colunas.
  # - Se todas as etapas preenchidas apontam para a mesma etapa errada → 1 erro único de arquivo
  # - Se há mix de etapas erradas ou valores não reconhecidos → erros por linha
  # - Em qualquer caso de erro → para aqui, não valida disciplina/série/descrição
  # - Se todas ok (ou em branco) → segue para parse_data_rows
  def validate_csv_step(data_rows, offset)
    step_errors = []
    rows_with_step = 0

    data_rows.each_with_index do |row, index|
      next if row[0].blank?

      raw_step = row[2]&.strip
      next if raw_step.blank?

      rows_with_step += 1
      row_number = offset + index + 1
      csv_step = match_step(raw_step)

      if csv_step.nil?
        step_errors << {
          row: row_number,
          field: 'Etapa',
          original_value: raw_step,
          message: t('step_not_recognized', value: raw_step, selected_step: step_label)
        }
      elsif csv_step != @step
        step_errors << {
          row: row_number,
          field: 'Etapa',
          original_value: raw_step,
          message: t('step_diverges', value: raw_step, selected_step: step_label),
          detected_step: csv_step
        }
      end
    end

    return true if step_errors.empty?

    # Erro único de arquivo somente quando TODAS as linhas com etapa apontam para a mesma etapa errada
    detected_steps = step_errors.map { |e| e[:detected_step] }.compact.uniq
    if detected_steps.size == 1 && step_errors.size == rows_with_step && step_errors.all? { |e| e[:detected_step] }
      @errors << {
        row: 0, field: 'arquivo', original_value: '',
        message: t('step_wrong_file', detected_step: STEP_LABELS[detected_steps.first], selected_step: step_label)
      }
    else
      step_errors.each { |e| @errors << e.except(:detected_step) }
    end

    false
  end

  def parse_data_rows(data_rows, offset)
    seen_codes = {}

    data_rows.each_with_index do |row, index|
      row_number = offset + index + 1

      next if row.all?(&:blank?)

      if row[0].blank?
        add_error(row_number, 'Código', '')
        next
      end

      code = row[0].strip

      if seen_codes[code]
        @errors << {
          row: row_number,
          field: 'Código',
          original_value: code,
          message: t('duplicate_code', code: code, first_row: seen_codes[code])
        }
        next
      end

      seen_codes[code] = row_number

      if child_school?
        parse_child_school_row(row, row_number)
      else
        parse_elementary_school_row(row, row_number)
      end
    end
  end

  def parse_child_school_row(row, row_number)
    fields = extract_child_school_fields(row)
    validate_child_school_fields(fields, row_number)

    return unless child_school_fields_valid?(fields)

    @records << build_child_school_record(fields)
  end

  def parse_elementary_school_row(row, row_number)
    fields = extract_elementary_school_fields(row)
    validate_elementary_school_fields(fields, row_number)

    return unless elementary_school_fields_valid?(fields)

    @records << build_elementary_school_record(fields)
  end

  def extract_child_school_fields(row)
    {
      code: row[0].strip,
      raw_experience_field: row[1]&.strip,
      raw_grades: row[3]&.strip,
      raw_description: row[4]&.strip
    }
  end

  def extract_elementary_school_fields(row)
    {
      code: row[0].strip,
      raw_discipline: row[1]&.strip,
      raw_grades: row[3]&.strip,
      raw_thematic_unit: row[4]&.strip,
      raw_description: row[5]&.strip
    }
  end

  def validate_child_school_fields(fields, row_number)
    fields[:experience_field] = match_experience_field(fields[:raw_experience_field])
    fields[:grades] = parse_grades(fields[:raw_grades], row_number)

    validate_experience_field(fields, row_number)
    validate_description(fields, row_number)
  end

  def validate_elementary_school_fields(fields, row_number)
    fields[:discipline] = match_discipline(fields[:raw_discipline])
    fields[:grades] = parse_grades(fields[:raw_grades], row_number)

    validate_discipline(fields, row_number)
    validate_description(fields, row_number)
  end

  def validate_experience_field(fields, row_number)
    if fields[:raw_experience_field].blank?
      add_error(row_number, 'Campo de Experiência', '')
    elsif fields[:experience_field].nil?
      add_error(row_number, 'Campo de Experiência', fields[:raw_experience_field])
    end
  end

  def validate_discipline(fields, row_number)
    if fields[:raw_discipline].blank?
      add_error(row_number, 'Componente Curricular', '')
    elsif fields[:discipline].nil?
      add_error(row_number, 'Componente Curricular', fields[:raw_discipline])
    end
  end

  def validate_description(fields, row_number)
    return unless fields[:raw_description].blank?

    add_error(row_number, 'Objetivo/habilidade', '')
  end

  def child_school_fields_valid?(fields)
    fields[:experience_field] &&
      fields[:grades]&.any? && fields[:raw_description].present?
  end

  def elementary_school_fields_valid?(fields)
    fields[:discipline] &&
      fields[:grades]&.any? && fields[:raw_description].present?
  end

  def build_child_school_record(fields)
    {
      code: fields[:code],
      field_of_experience: fields[:experience_field],
      step: @step,
      grades: fields[:grades],
      description: fields[:raw_description]
    }
  end

  def build_elementary_school_record(fields)
    {
      code: fields[:code],
      discipline: fields[:discipline],
      step: @step,
      grades: fields[:grades],
      thematic_unit: fields[:raw_thematic_unit],
      description: fields[:raw_description]
    }
  end

  def parse_grades(raw_grades, row_number)
    if raw_grades.blank?
      add_error(row_number, 'Série', '')
      return []
    end

    valid_grades = GRADES_BY_STEP[@step] || []

    raw_grades.split(',').map(&:strip).map do |raw_grade|
      grade = match_grade(raw_grade)

      if grade.nil?
        add_error(row_number, 'Série', raw_grade)
      elsif !valid_grades.include?(grade)
        @errors << {
          row: row_number,
          field: 'Série',
          original_value: raw_grade,
          message: t('grade_not_in_step', value: raw_grade, selected_step: step_label)
        }
        grade = nil
      end

      grade
    end.compact
  end

  def child_school?
    @step == 'child_school'
  end

  def add_error(row_number, field, original_value)
    message = if original_value.present?
                t('field_not_recognized', field: field, value: original_value, selected_step: step_label)
              else
                t('field_blank', field: field)
              end

    @errors << {
      row: row_number,
      field: field,
      original_value: original_value.to_s,
      message: message
    }
  end

  def t(key, **options)
    I18n.t("services.learning_objectives_and_skills_csv_parser.#{key}", **options)
  end

  def step_label
    STEP_LABELS[@step]
  end
end
