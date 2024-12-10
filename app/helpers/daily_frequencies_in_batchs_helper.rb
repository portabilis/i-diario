module DailyFrequenciesInBatchsHelper
  def data_additional(date, student)
    additional_class = nil
    tooltip = nil

    @additional_data.each do |additional_data|
      if additional_data[:date] == date[:date] && additional_data[:student_id] == student[:student][:id]
        additional_class = additional_data[:additional_class]
        tooltip = additional_data[:tooltip]
      end
    end

    {
      response_class: additional_class,
      response_tooltip: tooltip
    }
  end

  def custom_student_name(student)
    student_name = student[:student][:name]
    color = false

    @additional_data.each do |additional_data|
      if additional_data[:student_id] == student[:student][:id]
        student_name = '*' + student[:student][:name]
        color = '#a90329'
      end
    end

    {
      name: student_name,
      color: color
    }
  end
end

