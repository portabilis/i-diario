class MaximumScoreFetcher

  def initialize(avaliation)
    @avaliation = avaliation
  end

  def maximum_score
    return avaliation.test_setting.maximum_score if avaliation.test_setting.arithmetic_calculation_type?
    return avaliation.weight.to_f if avaliation.test_setting.arithmetic_and_sum_calculation_type?
    return avaliation.weight.to_f if avaliation.test_setting_test.allow_break_up
    return avaliation.test_setting_test.weight if !avaliation.test_setting_test.allow_break_up
  end

  private
  attr_accessor :avaliation
end
