class Select2PeriodInput < Select2Input
  def input(wrapper_options)
    raise 'User must be passed' unless options[:user].is_a? User

    if (classroom = options[:user].current_classroom)
      if classroom.period != Periods::FULL.to_s
        input_html_options[:readonly] = 'readonly'
        input_html_options[:value] = classroom.period
      end
    end

    super(wrapper_options)
  end

  def parse_collection
    classroom_period = options[:user].current_classroom.try(:period)
    periods = JSON.parse(PeriodsDecorator.data_for_select2)

    if classroom_period == Periods::FULL
      periods.keep_if do |period|
        [Periods::FULL, Periods::MATUTINAL, Periods::VESPERTINE].include?(period['id'])
      end
    else
      periods.keep_if { |period| period['id'] == classroom_period }
    end

    options[:elements] = periods.to_json

    super
  end
end
