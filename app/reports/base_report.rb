require 'action_view'
require 'prawn/measurement_extensions'

class BaseReport
  include Prawn::View
  include I18n::Alchemy::NumericParser
  include ActionView::Helpers::NumberHelper

  GAP = 8.freeze

  def initialize(page_layout = :portrait)
    current_configuration = GeneralConfiguration.current
    @display_header_on_all_reports_pages = current_configuration.display_header_on_all_reports_pages
    @display_daily_activies_log = current_configuration.display_daily_activies_log
    @show_daily_activities_in_knowledge_area_content_record_report =
      current_configuration.show_daily_activities_in_knowledge_area_content_record_report

    @document = Prawn::Document.new(
      page_size: 'A4',
      page_layout: page_layout,
      left_margin: 5.mm,
      right_margin: 5.mm,
      top_margin: 5.mm,
      bottom_margin: 5.mm
    )
  end

  protected

  def page_header
    repeat(lambda { |pg| (@display_header_on_all_reports_pages ? true : pg == 1) }) do
      yield
    end

    @cursor_page = cursor - GAP

    move_down GAP unless @display_header_on_all_reports_pages
  end

  def page_content
    @cursor_page = cursor unless page_number == 1 || @display_header_on_all_reports_pages

    if @display_header_on_all_reports_pages
      bounding_box([0, @cursor_page], width: bounds.width, height: @cursor_page - 10) do
        yield
      end
    else
      yield
    end
  end

  def page_footer(draw_datetime: false)
    yield if block_given?

    repeat(:all) { draw_text("Data e hora: #{Time.zone.now.strftime("%d/%m/%Y %H:%M")}", size: 8, at: [0, 0]) } if draw_datetime

    string = "Página <page> de <total>"

    options = {
      at: [bounds.right - 150, 6],
      width: 150,
      size: 8,
      align: :right
    }

    number_pages(string, options)
  end

  def footer
    page_footer(draw_datetime: true)
  end

  def inline_formated_cell_header(text)
    "<font size='8'><b>#{text}</b></font>\n"
  end

  def numeric_parser
    I18n::Alchemy::NumericParser
  end

  def numeric_precision(value, precision: 2)
    number_with_precision(value, precision: precision)
  end

  def numeric_truncate_precision(value, precision: 2)
    value.truncate(precision)
  end

  def text_box_truncate(title, information)
    start_new_page if cursor < 45

    draw_text(title, size: 8, style: :bold, at: [5, cursor - 10])

    begin
      if information.class.eql?(Array)
        text_formatted = []

        information.each do |text|
          if text[:styles].include?(:bold)
            text[:text] = "<b>#{text[:text]}</b>"
          end
          if text[:styles].include?(:italic)
            text[:text] = "<i>#{text[:text]}</i>"
          end
          if text[:styles].include?(:underline)
            text[:text]= "<u>#{text[:text]}</u>"
          end

          text_formatted << text[:text]
        end

        information = text_formatted.join(" ")
      end

      text_height = height_of(information, width: bounds.width - 10, size: 10) + 180
      box_height = (text_height > cursor ? cursor : text_height)

      bounding_box([0, cursor], width: bounds.width, height: box_height - 5) do
        line_width 0.5
        stroke_bounds
        information = text_box(
          information.gsub("</p>", "</p><br>"),
          width: bounds.width - 10,
          overflow: :truncate,
          size: 10,
          at: [5, box_height - 20],
          inline_format: true
        )
      end

      start_new_page if information.present?
    end while information.present?
  end

  def text_box_overflow_to_new_page(information, size, at, width, height)
    begin
      if information.class.eql?(Array)
        text_formatted = []

        text_formatted << information.map { |text| text[:text] }

        information = text_formatted.join(" ")
      end

      information = text_box(
        information,
        size: size,
        at: at,
        width: width,
        height: height,
        overflow: :truncate,
        inline_format: true
      )

      if information.present?
        start_new_page
        at = nil
        height = bounds.height
      end
    end while information.present?
  end
end
