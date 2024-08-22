class AttendanceRecordReport < BaseReport
  # This number represent how many students are printed on each page
  STUDENT_BY_PAGE_COUNT = 29

  # This factor represent the quantitty of students with social name needed to reduce 1 student by page
  SOCIAL_NAME_REDUCTION_FACTOR = 2

  def self.build(
    entity_configuration,
    teacher,
    year,
    start_at,
    end_at,
    daily_frequencies,
    enrollment_classrooms_list,
    events,
    school_calendar,
    second_teacher_signature,
    students_frequencies_percentage,
    current_user,
    classroom_id
  )
    new(:landscape)
      .build(entity_configuration,
             teacher,
             year,
             start_at,
             end_at,
             daily_frequencies,
             enrollment_classrooms_list,
             events,
             school_calendar,
             second_teacher_signature,
             students_frequencies_percentage,
             current_user,
             classroom_id)

  end

  def build(
    entity_configuration,
    teacher,
    year,
    start_at,
    end_at,
    daily_frequencies,
    enrollment_classrooms_list,
    events,
    school_calendar,
    second_teacher_signature,
    students_frequencies_percentage,
    current_user,
    classroom_id
  )
    @entity_configuration = entity_configuration
    @teacher = set_teacher(teacher, classroom_id, current_user)
    @year = year
    @start_at = start_at
    @end_at = end_at
    @daily_frequencies = daily_frequencies
    @enrollment_classrooms = enrollment_classrooms_list
    @events = events
    @school_calendar = school_calendar
    @second_teacher_signature = ActiveRecord::Type::Boolean.new.cast(second_teacher_signature)
    @show_legend_hybrid = false
    @show_legend_remote = false
    @exists_legend_hybrid = false
    @exists_legend_remote = false
    @students_frequency_percentage = students_frequencies_percentage

    self.legend = 'Legenda: N - Não enturmado, D - Dispensado da disciplina, FJ - Falta justificada'

    @general_configuration = GeneralConfiguration.first
    @show_percentage_on_attendance = @general_configuration.show_percentage_on_attendance_record_report
    @show_inactive_enrollments = @general_configuration.show_inactive_enrollments
    @do_not_send_justified_absence = @general_configuration.do_not_send_justified_absence

    header
    content
    footer

    self
  end

  protected

  attr_accessor :any_student_with_dependence, :legend, :extra_school_event_description

  private

  def header
    attendance_header = make_cell(content: 'Registro de frequência', size: 12, font_style: :bold, background_color: 'DEDEDE', height: 20, padding: [2, 2, 4, 4], align: :center, colspan: 6)
    begin
      logo_cell = make_cell(image: open(@entity_configuration.logo.url), fit: [50, 50], width: 70, rowspan: 4, position: :center, vposition: :center)
    rescue StandardError
      logo_cell = make_cell(content: '', width: 70, rowspan: 4)
    end

    entity_name = @entity_configuration ? @entity_configuration.entity_name : ''
    organ_name = @entity_configuration ? @entity_configuration.organ_name : ''

    entity_organ_and_unity_cell = make_cell(content: "#{entity_name}\n#{organ_name}\n#{@daily_frequencies.first.unity.name}", size: 12, leading: 1.5, align: :center, valign: :center, rowspan: 4, padding: [6, 0, 8, 0])
    classroom_header = make_cell(content: 'Turma', size: 8, font_style: :bold, width: 100, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2, colspan: 2)
    year_header = make_cell(content: 'Ano letivo', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    period_header = make_cell(content: 'Período', size: 8, font_style: :bold, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    discipline_header = make_cell(content: 'Disciplina', size: 8, font_style: :bold, width: 200, colspan: 3, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    teacher_header = make_cell(content: 'Professor', size: 8, font_style: :bold, width: 200, borders: [:top, :left, :right], padding: [2, 2, 4, 4], height: 2)
    classroom_cell = make_cell(content: @daily_frequencies.first.classroom.description, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4, colspan: 2)
    year_cell = make_cell(content: @year.to_s, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)
    period_cell = make_cell(content: "De #{@start_at} a #{@end_at}", size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)
    discipline_cell = make_cell(content: discipline_display, size: 10, colspan: 3, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)
    teacher_cell = make_cell(content: @teacher.name, size: 10, borders: [:bottom, :left, :right], padding: [0, 2, 4, 4], height: 4)

    first_table_data = [[attendance_header],
                        [logo_cell, entity_organ_and_unity_cell, classroom_header, year_header, period_header],
                        [classroom_cell, year_cell, period_cell],
                        [discipline_header, teacher_header],
                        [discipline_cell, teacher_cell]]

    page_header do
      table(first_table_data, width: bounds.width, header: true) do
        cells.border_width = 0.25
        row(0).border_top_width = 0.25
        row(-1).border_bottom_width = 0.25
        column(0).border_left_width = 0.25
        column(-1).border_right_width = 0.25
      end
    end
  end

  def daily_frequencies_table
    self.any_student_with_dependence = false

    daily_frequencies = @daily_frequencies.reject { |daily_frequency| !daily_frequency.students.any? }
    frequencies_and_events = daily_frequencies.to_a + @events.to_a

    @daily_frequency_students = DailyFrequencyStudent.by_daily_frequency_id(@daily_frequencies.map(&:id)).to_a

    frequencies_and_events = frequencies_and_events.sort_by do |obj|
      daily_frequency?(obj) ? obj.frequency_date : obj[:date]
    end

    unless @show_inactive_enrollments
      @enrollment_classrooms= @enrollment_classrooms.uniq { |enrollment_classroom| enrollment_classroom[:student].id }
    end

    student_enrollment_ids ||= @enrollment_classrooms.map { |student_enrollment|
      student_enrollment[:student_enrollment].id
    }

    active_searches = active_searches_by_range(daily_frequencies, student_enrollment_ids)
    all_dependances = StudentEnrollmentDependence.where(student_enrollment_id: student_enrollment_ids)
    all_exempts = StudentEnrollmentExemptedDiscipline.by_student_enrollment(student_enrollment_ids)
                                                     .includes(student_enrollment: [:student]).to_a

    sliced_frequencies_and_events = frequencies_and_events.each_slice(40).to_a

    sliced_frequencies_and_events.each_with_index do |frequencies_and_events_slice, index|
      class_numbers = []
      days = []
      months = []
      students = {}

      frequencies_and_events_slice.each do |daily_frequency_or_event|
        if daily_frequency?(daily_frequency_or_event)
          daily_frequency = daily_frequency_or_event
          next unless frequency_in_period(daily_frequency) && is_school_day?(daily_frequency.frequency_date)

          class_numbers << make_cell(content: daily_frequency.class_number.to_s, background_color: 'FFFFFF', align: :center)
          days << make_cell(content: daily_frequency.frequency_date.day.to_s, background_color: 'FFFFFF', align: :center)
          months << make_cell(content: daily_frequency.frequency_date.month.to_s, background_color: 'FFFFFF', align: :center)

          @enrollment_classrooms.each do |enrollment_classroom|
            student_enrollment = enrollment_classroom[:student_enrollment]
            student = enrollment_classroom[:student]
            student_enrollment_classroom = enrollment_classroom[:student_enrollment_classroom]
            joined_at = enrollment_classroom[:student_enrollment_classroom].joined_at.to_date
            left_at = get_left_at(enrollment_classroom[:student_enrollment_classroom].left_at)
            sequence = enrollment_classroom[:student_enrollment_classroom].sequence

            if exempted_from_discipline?(all_exempts, student_enrollment, daily_frequency)
              student_frequency = ExemptedDailyFrequencyStudent.new
            elsif in_active_search?(student.id, active_searches, daily_frequency)
              @show_legend_active_search = true
              student_frequency = ActiveSearchFrequencyStudent.new
            elsif @show_inactive_enrollments
              frequency_date = daily_frequency.frequency_date.to_date
              if frequency_date >= joined_at && frequency_date < left_at
                student_frequency = daily_frequency.students.detect { |student_frequency| student_frequency.student_id.eql?(student.id) && student_frequency.active.eql?(true) }
              else
                student_frequency ||= NullDailyFrequencyStudent.new
              end
            else
              student_frequency = daily_frequency.students.detect { |student_frequency| student_frequency.student_id.eql?(student.id) && student_frequency.active.eql?(true) }
              student_frequency ||= NullDailyFrequencyStudent.new
            end

            if @show_legend_active_search && !@exists_active_search
              @exists_active_search = true
              self.legend += ', B - Busca ativa'
            end

            (students[student_enrollment_classroom.id] ||= {})[:name] = student.to_s
            students[student_enrollment_classroom.id] = {} if students[student_enrollment_classroom.id].nil?
            students[student_enrollment_classroom.id][:dependence] = students[student_enrollment_classroom.id][:dependence] || student_has_dependence?(all_dependances, student_enrollment, daily_frequency)
            self.any_student_with_dependence = self.any_student_with_dependence || students[student_enrollment_classroom.id][:dependence]
            students[student_enrollment_classroom.id][:absences] ||= 0
            students[student_enrollment_classroom.id][:sequence] ||= sequence if @show_inactive_enrollments

            if @show_percentage_on_attendance
              students[student_enrollment_classroom.id][:absences_percentage] = @students_frequency_percentage[student_enrollment.id]
            end

            unless student_frequency.present?
              absences = student_frequency.nil? ? 0 : 1
              if @do_not_send_justified_absence && student_frequency&.absence_justification_student_id
                absences = 0
              end

              students[student_enrollment_classroom.id][:absences] +=  absences
            end

            hybrid_or_remote = frequency_hybrid_or_remote(student_enrollment, daily_frequency)

            if hybrid_or_remote
              student_frequency = hybrid_or_remote
            else
              student_frequency
            end

            if @show_legend_hybrid && !@exists_legend_hybrid
              @exists_legend_hybrid = true
              self.legend += ', S - Modalidade semipresencial'
            elsif @show_legend_remote && !@exists_legend_remote
              @exists_legend_remote = true
              self.legend += ', R - Modalidade remota'
            end

            (students[student_enrollment_classroom.id][:attendances] ||= []) <<
              make_cell(content: student_frequency.to_s, align: :center)
          end
        else
          school_calendar_event = daily_frequency_or_event
          legend = ', ' + school_calendar_event[:legend].to_s + ' - ' + school_calendar_event[:description]
          self.legend += legend unless self.legend.include?(legend)

          class_numbers << make_cell(content: '', background_color: 'FFFFFF', align: :center)
          days << make_cell(content: school_calendar_event[:date].day.to_s, background_color: 'FFFFFF', align: :center)
          months << make_cell(content: school_calendar_event[:date].month.to_s, background_color: 'FFFFFF', align: :center)

          @enrollment_classrooms.each do |enrollment_classroom|
            student_enrollment = enrollment_classroom[:student_enrollment]
            student = enrollment_classroom[:student]
            student_enrollment_classroom = enrollment_classroom[:student_enrollment_classroom]
            sequence = enrollment_classroom[:student_enrollment_classroom].sequence

            (students[student_enrollment_classroom.id] ||= {})[:name] = student.to_s
            students[student_enrollment_classroom.id] = {} if students[student_enrollment_classroom.id].nil?
            students[student_enrollment_classroom.id][:absences] ||= 0
            students[student_enrollment_classroom.id][:social_name] = student.social_name
            students[student_enrollment_classroom.id][:sequence] ||= sequence if @show_inactive_enrollments

            if @show_percentage_on_attendance
              students[student_enrollment_classroom.id][:absences_percentage] = @students_frequency_percentage[student_enrollment.id]
            end

            (students[student_enrollment_classroom.id][:attendances] ||= []) << make_cell(content: (school_calendar_event[:legend]).to_s, align: :center)
          end
        end
      end

      sequential_number_header = make_cell(content: 'Nº', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center, valign: :center, rowspan: 3)
      student_name_header = make_cell(content: 'Nome do aluno', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center, valign: :center, rowspan: 3)
      class_number_header = make_cell(content: 'Aula', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center, width: 20)
      day_header = make_cell(content: 'Dia', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center)
      month_header = make_cell(content: 'Mês', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center)
      absences_header = make_cell(content: 'Faltas', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center, valign: :center, rowspan: 3)
      percentage_absences_header = make_cell(content: 'Freq.', size: 8, font_style: :bold, background_color: 'FFFFFF', align: :center, valign: :center, rowspan: 3)

      first_headers_and_class_numbers_cells = [sequential_number_header, student_name_header, class_number_header].concat(class_numbers)

      (40 - class_numbers.count).times { first_headers_and_class_numbers_cells << make_cell(content: '', background_color: 'FFFFFF') }

      first_headers_and_class_numbers_cells << absences_header

      first_headers_and_class_numbers_cells << percentage_absences_header if @show_percentage_on_attendance

      days_header_and_cells = [day_header].concat(days)

      (40 - days.count).times { days_header_and_cells << make_cell(content: '', background_color: 'FFFFFF') }

      months_header_and_cells = [month_header].concat(months)

      (40 - months.count).times { months_header_and_cells << make_cell(content: '', background_color: 'FFFFFF') }

      students_cells = []
      students = students.sort_by { |(_key, value)| value[:dependence] ? 1 : 0 }
      sequence = 1 unless @show_inactive_enrollments
      sequence_reseted = false

      students.each do |_key, value|
        if !sequence_reseted && value[:dependence]
          sequence = 1
          sequence_reseted = true
        end

        if @show_inactive_enrollments
          sequence_cell = make_cell(content: value[:sequence].to_s, align: :center)
        else
          sequence_cell = make_cell(content: sequence.to_s, align: :center)
        end

        student_cells = [sequence_cell, { content: (value[:dependence] ? '* ' : '') + value[:name], colspan: 2 }].concat(value[:attendances])

        (40 - value[:attendances].count).times { student_cells << nil }

        student_cells << make_cell(content: value[:absences].to_s, align: :center)

        if @show_percentage_on_attendance
          student_cells << make_cell(content: value[:absences_percentage] || '100%', align: :center)
        end

        students_cells << student_cells
        sequence += 1 unless @show_inactive_enrollments
      end

      bottom_offset = @second_teacher_signature ? 24 : 0
      sliced_students_cells = students_cells.each_slice(student_slice_size(students)).to_a

      sliced_students_cells.each_with_index do |students_cells_slice, slice_index|
        data = [
          first_headers_and_class_numbers_cells,
          days_header_and_cells,
          months_header_and_cells
        ]

        if slice_index == sliced_students_cells.count - 1 && index == sliced_frequencies_and_events.count - 1
          columns = @show_percentage_on_attendance ? 45 : 44
          students_cells_slice <<
            [{ content: "Aulas dadas: #{daily_frequencies.count}", colspan: columns, align: :center }]
        end

        data.concat(students_cells_slice)

        column_widths = { 0 => 20, 1 => 140, 43 => 30 }

        (3..42).each { |i| column_widths[i] = 13 }

        page_content do
          table(data, row_colors: ['FFFFFF', 'DEDEDE'], cell_style: { size: 8, padding: [2, 2, 2, 2] },
                      column_widths: column_widths, width: bounds.width) do |t|
            t.cells.border_width = 0.25

            t.before_rendering_page do |page|
              page.row(0).border_top_width = 0.25
              page.row(-1).border_bottom_width = 0.25
              page.column(0).border_left_width = 0.25
              page.column(-1).border_right_width = 0.25
            end
          end
        end

        text_box(self.legend, size: 8, at: [0, 30 + bottom_offset], width: 825, height: 20)

        start_new_page if slice_index < sliced_students_cells.count - 1
      end

      text_box(self.legend, size: 8, at: [0, 30 + bottom_offset], width: 825, height: 20)

      self.legend = 'Legenda: N - Não enturmado, D - Dispensado da disciplina, FJ - Falta justificada'

      if index < sliced_frequencies_and_events.count - 1
        start_new_page
      elsif show_school_day_event_description?
        events = format_legend(extra_school_events)
        height = 20
        at = [0, 50 + bottom_offset]

        if events.size > 485
          height = bounds.height
          at = [0, height]
          start_new_page
        end

        text_box_overflow_to_new_page(events, 8, at, 825, height)
      end
    end
  end

  def content
    daily_frequencies_table
  end

  def footer
    page_footer do
      repeat(:all) do
        if @second_teacher_signature
          draw_text('Assinatura do(a) professor(a):', size: 8, style: :bold, at: [0, 24])
          draw_text('________________________________________', size: 8, at: [117, 24])
        end

        draw_text('Assinatura do(a) professor(a):', size: 8, style: :bold, at: [0, 0])
        draw_text('________________________________________', size: 8, at: [117, 0])

        draw_text('Assinatura do(a) coordenador(a)/diretor(a):', size: 8, style: :bold, at: [300, 0])
        draw_text('________________________________________', size: 8, at: [470, 0])

        draw_text('Data:', size: 8, style: :bold, at: [652, 0])
        draw_text('________________', size: 8, at: [674, 0])

        if any_student_with_dependence
          offset = @second_teacher_signature ? 24 : 0
          draw_text('* Alunos cursando dependência', size: 8, at: [0, 47 + offset])
        end
      end
    end
  end

  def get_left_at(left_at)
    left_at.empty? ? Date.current.end_of_year : left_at.to_date
  end

  def event?(record)
    record.class.to_s == 'SchoolCalendarEvent'
  end

  def daily_frequency?(record)
    record.is_a? DailyFrequency
  end

  def student_has_dependence?(all_dependances, student_enrollment, daily_frequency)
    all_dependances.detect do |dependency|
      dependency.student_enrollment_id.eql?(student_enrollment.id) &&
        dependency.discipline_id.eql?(daily_frequency.discipline_id)
    end
  end

  def exempted_from_discipline?(all_exempts, student_enrollment, daily_frequency)
    return false if daily_frequency.discipline_id.blank?

    step_number = step_number(daily_frequency)
    discipline_id = daily_frequency.discipline_id

    exemption = all_exempts.detect { |exempt|
                  exempt.student_enrollment_id.eql?(student_enrollment.id) &&
                    exempt.discipline_id.eql?(discipline_id) &&
                    exempt.steps.split(',').include?(step_number.to_s)
                }

    exemption.present?
  end

  def student_slice_size(students)
    student_with_social_name_count = students.select { |(_key, value)|
      value[:social_name].present?
    }.length

    second_signature_offset = @second_teacher_signature ? 3 : 0
    social_name_factor = (student_with_social_name_count / SOCIAL_NAME_REDUCTION_FACTOR)

    slice_size = STUDENT_BY_PAGE_COUNT - second_signature_offset - social_name_factor

    return slice_size unless show_school_day_event_description?

    slice_size - 3
  end

  def step_number(daily_frequency)
    @steps ||= StepsFetcher.new(daily_frequency.classroom).steps

    step = @steps.detect { |step|
      step[:start_at] <= daily_frequency.frequency_date && step[:end_at] >= daily_frequency.frequency_date
    }

    step&.to_number
  end

  def frequency_in_period(daily_frequency)
    step_number(daily_frequency).present?
  end

  def discipline_display
    return 'Geral' if general_frequency?

    discipline.to_s
  end

  def classroom_has_general_absence?
    classroom.first_exam_rule.frequency_type == FrequencyTypes::GENERAL
  end

  def teacher_allow_absence_by_discipline?
    @teacher_allow_absence_by_discipline ||= TeacherDisciplineClassroom.by_classroom(classroom.id)
                                                                       .by_teacher_id(@teacher.id)
                                                                       .by_discipline_id(discipline.id)
                                                                       .first
                                                                       .try(:allow_absence_by_discipline)
  end

  def active_searches_by_range(daily_frequencies, student_enrollment_ids)
    dates = daily_frequencies.map(&:frequency_date).uniq

    ActiveSearch.new.in_active_search_in_range(student_enrollment_ids, dates)
  end

  def in_active_search?(student_id, active_searches, daily_frequency)
    active_searches.detect do |active_searche|
      active_searche[:date].eql?(daily_frequency.frequency_date) && active_searche[:student_ids].include?(student_id)
    end
  end

  def general_frequency?
    discipline.blank?
  end

  def knowledge_area
    @knowledge_area ||= discipline.knowledge_area
  end

  def discipline
    @discipline ||= @daily_frequencies.first.discipline
  end

  def classroom
    @classroom ||= @daily_frequencies.first.classroom
  end

  def extra_school_events
    @extra_school_events ||= @school_calendar.events.select { |event|
      event.event_type == EventTypes::EXTRA_SCHOOL &&
        event.show_in_frequency_record &&
        report_include_event_date?(event)
    }
  end

  def show_school_day_event_description?
    return false if extra_school_events.empty?

    true
  end

  def report_include_event_date?(event)
    ((event.start_date..event.end_date).to_a & (@start_at.to_date..@end_at.to_date).to_a).any?
  end

  def format_legend(events)
    all_events = []

    events.each do |event|
      event_date = if event.start_date == event.end_date
                     event.start_date.strftime('%d/%m/%Y').to_s
                   else
                     "#{event.start_date.strftime('%d/%m/%Y')} à #{event.end_date.strftime('%d/%m/%Y')}"
                   end

      all_events << "#{event.description}: #{event_date}"
    end

    all_events.join(', ')
  end

  def frequency_hybrid_or_remote(student_enrollment, daily_frequency)
    student_frequency = @daily_frequency_students.detect { |student_frequency|
      student_frequency.student_id.eql?(student_enrollment.student_id)
    }

    return if student_frequency.blank?
    return if student_frequency.type_of_teaching == TypesOfTeaching::PRESENTIAL

    if student_frequency.type_of_teaching == TypesOfTeaching::HYBRID
      @show_legend_hybrid = true
      'S'
    else
      @show_legend_remote = true
      'R'
    end
  end

  def is_school_day?(date)
    return true if @events.empty?

    @events.detect { |event| event[:date].eql?(date) && event[:type].eql?(EventTypes::NO_SCHOOL) }.blank?
  end

  def set_teacher(teacher, classroom_id, current_user)
    return teacher unless current_user.current_role_is_admin_or_employee?

    teachers = Classroom.find(classroom_id).teacher_discipline_classrooms.map(&:teacher)
    teachers.include?(teacher) ? teacher : teachers.first
  end
end
