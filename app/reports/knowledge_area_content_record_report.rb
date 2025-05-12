class KnowledgeAreaContentRecordReport < BaseReport
  def self.build(entity_configuration, date_start, date_end, knowledge_area_content_records, current_teacher)
    new.build(entity_configuration, date_start, date_end, knowledge_area_content_records, current_teacher)
  end

  def build(entity_configuration, date_start, date_end, knowledge_area_content_records, current_teacher)
    @entity_configuration = entity_configuration
    @date_start = date_start
    @date_end = date_end
    @knowledge_area_content_records = knowledge_area_content_records
    @current_teacher = current_teacher
    attributes

    header
    body
    footer

    self
  end

  private

  def header
    entity_name = @entity_configuration.try(:entity_name).to_s
    organ_name = @entity_configuration.try(:organ_name).to_s
    title = 'Registros de conteúdos por áreas de conhecimento - Registros de conteúdo'

    header_cell = make_cell(
      content: title,
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 2
    )

    begin
      entity_logo_cell = make_cell(
        image: open(@entity_configuration.logo.url),
        fit: [50, 50],
        width: 70,
        rowspan: 4,
        position: :center,
        vposition: :center
      )
    rescue
      entity_logo_cell = make_cell(content: '', width: 70, rowspan: 4)
    end

    entity_organ_and_unity_cell = make_cell(
      content: "#{entity_name}\n#{organ_name}\n" + "#{@knowledge_area_content_records.first.content_record.unity.name}",
      size: 12,
      leading: 1.5,
      align: :center,
      valign: :center,
      rowspan: 4,
      padding: [6, 0, 8, 0]
    )

    table_data = [
      [header_cell],
      [
        entity_logo_cell,
        entity_organ_and_unity_cell
      ]
    ]

    page_header do
      table(table_data, width: bounds.width) do
        cells.border_width = 0.25
        row(0).border_top_width = 0.25
        row(-1).border_bottom_width = 0.25
        column(0).border_left_width = 0.25
        column(-1).border_right_width = 0.25
      end
    end
  end

  def attributes
    @identification_header_cell = make_cell(
      content: 'Identificação',
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 5
    )

    @general_information_header_cell = make_cell(
      content: 'Informações gerais',
      size: 12,
      font_style: :bold,
      background_color: 'DEDEDE',
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 5
    )
    @unity_header = make_cell(content: 'Unidade', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4])
    @classroom_header = make_cell(content: 'Turma', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4])
    @teacher_header = make_cell(content: 'Professor', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4])
    @period_header = make_cell(content: 'Período', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4])
    if @show_daily_activities_in_knowledge_area_content_record_report
      @daily_acitivies_header = make_cell(content: 'Registro das atividades', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4])
    end

    @unity_cell = make_cell(content:  @knowledge_area_content_records.first.content_record.unity.name, borders: [:bottom, :left, :right], size: 10, width: 240, align: :left, padding: [0, 2, 4, 4])
    @classroom_cell = make_cell(content: @knowledge_area_content_records.first.content_record.classroom.description, borders: [:bottom, :left, :right], size: 10, align: :left, padding: [0, 2, 4, 4])
    @teacher_cell = make_cell(content: @current_teacher.name, borders: [:bottom, :left, :right], size: 10, align: :left, padding: [0, 2, 4, 4])
    @period_cell = make_cell(content: (@date_start == '' || @date_end == '' ? '-' : "#{@date_start} a #{@date_end}"), borders: [:bottom, :left, :right], size: 10, align: :left, padding: [0, 2, 4, 4])

    @record_date_header = make_cell(content: 'Data', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4])
    @knowledge_area_header = make_cell(content: 'Áreas de conhecimento', size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4])
    @conteudo_header = make_cell(content: Translator.t('activerecord.attributes.knowledge_area_content_record.contents'), size: 8, font_style: :bold, borders: [:left, :right, :top], background_color: 'FFFFFF', padding: [2, 2, 4, 4])
  end

  def identification
    title_identification = [
      [@identification_header_cell]
    ]

    identification_table_data = [
      [@unity_header, @classroom_header],
      [@unity_cell, @classroom_cell],
      [@teacher_header, @period_header],
      [@teacher_cell, @period_cell]
    ]

    table(title_identification, width: bounds.width, header: true) do
      cells.border_width = 0.25
      row(0).border_top_width = 0.25
      row(-1).border_bottom_width = 0.25
      column(0).border_left_width = 0.25
      column(-1).border_right_width = 0.25
    end

    table(identification_table_data, width: bounds.width, header: true) do
      cells.border_width = 0.25
      row(0).border_top_width = 0.25
      row(-1).border_bottom_width = 0.25
      column(0).border_left_width = 0.25
      column(-1).border_right_width = 0.25
    end

    move_down GAP
  end

  def general_information
    title_general_information = [
      [@general_information_header_cell]
    ]

    general_information_headers = [
      @record_date_header,
      @knowledge_area_header,
      @conteudo_header
    ]

    if @show_daily_activities_in_knowledge_area_content_record_report
      general_information_headers << @daily_acitivies_header
    end

    general_information_cells = []

    @knowledge_area_content_records.each do |knowledge_area_content_record|
      knowledge_area_descriptions = knowledge_area_content_record.knowledge_areas.map(&:description).join(", ")
      record_date_cell = make_cell(content: knowledge_area_content_record.content_record.record_date.strftime("%d/%m/%Y"), size: 10, width: 80, align: :left)
      content_cell = make_cell(content: content_cell_content(knowledge_area_content_record.content_record), size: 10, align: :left)
      knowledge_area_cell = make_cell(content: knowledge_area_descriptions, size: 10, width: 150, align: :left)

      if @show_daily_activities_in_knowledge_area_content_record_report
        daily_activties_cell = make_cell(content: knowledge_area_content_record.content_record.daily_activities_record.to_s, size: 10, align: :left)
      end

      general_information_cells << [
        record_date_cell,
        knowledge_area_cell,
        content_cell
      ]

      if @show_daily_activities_in_knowledge_area_content_record_report
        general_information_cells.last << daily_activties_cell
      end
    end

    general_information_table_data = [general_information_headers]
    general_information_table_data.concat(general_information_cells)

    table(title_general_information, width: bounds.width, header: true) do
      cells.border_width = 0.25
      row(0).border_top_width = 0.25
      row(-1).border_bottom_width = 0.25
      column(0).border_left_width = 0.25
      column(-1).border_right_width = 0.25
    end

    table(general_information_table_data, row_colors: ['DEDEDE', 'FFFFFF'], width: bounds.width, header: true) do
      cells.border_width = 0.25
      row(0).border_top_width = 0.25
      row(-1).border_bottom_width = 0.25
      column(0).border_left_width = 0.25
      column(-1).border_right_width = 0.25
    end
  end

  def body
    page_content do
      identification
      general_information
      signatures
    end
  end

  def content_cell_content(content_record)
    content_record.contents_ordered.map(&:to_s).join(', ')
  end

  def signatures
    start_new_page if cursor < 45
    move_down 30
    text_box("______________________________________________\nProfessor(a)", size: 10, align: :center, at: [0, cursor], width: 260)
    text_box("______________________________________________\nCoordenador(a)/diretor(a)", size: 10, align: :center, at: [306, cursor], width: 260)
  end
end
