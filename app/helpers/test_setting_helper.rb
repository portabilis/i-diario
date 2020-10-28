module TestSettingHelper
  def show_checked(test_setting)
    @show_checked ||= Hash.new do |h, record|
      h[record] = (record.default_division_weight && record.default_division_weight > 1) || weight_error(record)
    end

    @show_checked[test_setting]
  end

  def weight_error(test_setting)
    @weight_error ||= Hash.new do |h, record|
      h[record] = record.errors.messages[:default_division_weight]&.any?
    end

    @weight_error[test_setting]
  end
end
