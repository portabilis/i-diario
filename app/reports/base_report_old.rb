require 'prawn/measurement_extensions'

class BaseReportOld < BaseReport
  include Prawn::View

  TRANSLATION_SCOPE = 'reports.base_report'.freeze
  GRAY = 'DEDEDE'.freeze
  WHITE = 'FFFFFF'.freeze

  def initialize(entity_configuration, form)
    @entity_configuration = entity_configuration
    @form = form

    super()
  end

  def build
    header
    body
    footer

    self
  end

  protected

  attr_accessor :entity_configuration, :form, :document

  def title
    raise NotImplementedError
  end

  def header
    table_data = [
      [make_header_title_cell],
      [make_entity_logo_cell, make_entity_organ_and_unity_cell]
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

  def body
    raise NotImplementedError
  end

  def footer
    repeat(:all) do
      draw_text(
        I18n.t(
          :date_and_time,
          scope: TRANSLATION_SCOPE,
          date_time: Time.zone.now.strftime(
            I18n.t(:date_time_format, scope: TRANSLATION_SCOPE)
          )
        ),
        size: 8,
        at: [0, 0]
      )
    end

    number_pages(
      I18n.t(:number_pages, scope: TRANSLATION_SCOPE),
      {
        at: [bounds.right - 150, 6],
        width: 150,
        size: 8,
        align: :right
      }
    )
  end

  def make_table_header_cell(content, options = {})
    options[:size] = 12
    options[:font_style] = :bold
    options[:align] = :center
    options[:background_color] = GRAY
    options[:height] = 20
    options[:padding] = [2, 2, 4, 4]

    make_cell(content, options)
  end

  def make_row_header_cell(content, options = {})
    options[:size] = 8
    options[:font_style] = :bold
    options[:borders] = [:left, :right, :top]
    options[:padding] = [2, 2, 4, 4]

    make_cell(content, options)
  end

  def make_content_cell(content, options = {})
    options[:size] =  10
    options[:align] = :left
    options[:borders] = [:bottom, :left, :right]
    options[:padding] = [0, 2, 4, 4]

    make_cell(content, options)
  end

  def make_row_cell(content, options = {})
    options[:size] = 10
    options[:align] = :left

    make_cell(content, options)
  end

  def t(*args)
    options = args.extract_options!
    options[:scope] = translation_scope
    I18n.t(*(args + [options]))
  end

  def translation_scope
    raise NotImplementedError
  end

  private

  def entity_name
    @entity_configuration ? @entity_configuration.entity_name : ''
  end

  def organ_name
    @entity_configuration ? @entity_configuration.organ_name : ''
  end

  def make_header_title_cell
    make_cell(
      content: title,
      size: 12,
      font_style: :bold,
      background_color: GRAY,
      height: 20,
      padding: [2, 2, 4, 4],
      align: :center,
      colspan: 2
    )
  end

  def make_entity_logo_cell
    begin
      make_cell(
        image: open(@entity_configuration.logo.url),
        fit: [50, 50],
        width: 70,
        rowspan: 4,
        position: :center,
        vposition: :center
      )
    rescue
      make_cell(content: '', width: 70, rowspan: 4)
    end
  end

  def make_entity_organ_and_unity_cell
    make_cell(
      content: "#{entity_name}\n#{organ_name}\n" + "#{@form.unity}",
      size: 12,
      leading: 1.5,
      align: :center,
      valign: :center,
      rowspan: 4,
      padding: [6, 0, 8, 0]
    )
  end
end
