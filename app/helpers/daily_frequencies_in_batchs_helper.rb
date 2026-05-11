module DailyFrequenciesInBatchsHelper
  def data_additional(date, student)
    additional_class = nil
    tooltip = nil
    in_active_search_active = false
    student_id = student[:student][:id]

    @additional_data.each do |addit_data|
      if addit_data[:date] == date[:date] && addit_data[:student_id] == student_id
        additional_class = addit_data[:additional_class]
        tooltip = addit_data[:tooltip]
        in_active_search_active = addit_data[:in_active_search_active] || false
      end
    end

    if tooltip == 'Não enturmado' && student[:left_at].blank? && date[:date] >= student[:joined_at].to_date
      additional_class = nil
      tooltip = nil
    end

    {
      response_class: additional_class,
      response_tooltip: tooltip,
      in_active_search_active: in_active_search_active
    }
  end

  def custom_student_name(student, dates)
    student_name = student[:student][:name]
    color = false
    in_active_search_active = false
    has_enrolled = dates.pluck(:date).any? { |date| date > student[:joined_at].to_date }

    @additional_data.each do |additional_data|
      if additional_data[:student_id] == student[:student][:id]
        if additional_data[:in_active_search_active]
          in_active_search_active = true
        else
          student_name = '*' + student[:student][:name]
          color = '#a90329'
        end
      end
    end

    if color == '#a90329' && student[:left_at].blank? && has_enrolled
      student_name = student[:student][:name]
      color = false
    end

    {
      name: student_name,
      color: color,
      in_active_search_active: in_active_search_active
    }
  end
end
