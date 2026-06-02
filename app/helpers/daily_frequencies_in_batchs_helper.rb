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

  def student_statuses_for(student)
    student_additional_data = @additional_data.select { |data| data[:student_id] == student[:student][:id] }
    statuses = student_additional_data.map { |data| data[:status] }

    {
      name: student[:student][:name],
      inactive: inactive_badge_for?(student, student_additional_data),
      dependence: statuses.include?(:dependence),
      exempted_from_discipline: statuses.include?(:exempted_from_discipline),
      in_active_search: statuses.include?(:active_search)
    }
  end

  def inactive_badge_for?(student, student_additional_data)
    student_additional_data.any? do |data|
      next false unless data[:status] == :inactive

      !(student[:left_at].blank? && data[:date] >= student[:joined_at].to_date)
    end
  end
end
