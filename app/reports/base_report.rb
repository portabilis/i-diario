require 'prawn/measurement_extensions'

class BaseReport
  include Prawn::View

  GAP = 8.freeze

  def initialize(page_layout = :portrait)
    @display_header_on_all_reports_pages = GeneralConfiguration.current.display_header_on_all_reports_pages

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
end
