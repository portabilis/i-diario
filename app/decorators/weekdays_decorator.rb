class WeekdaysDecorator
  def self.checkbox_collection
    I18n.t('date.day_names').each_with_index.map do |day_name, index|
      OpenStruct.new({ weekday: day_name, id: index.to_s })
    end
  end

  def self.data_for_select2
    I18n.t('date.day_names').each_with_index.map do |day_name, index|
      { id: index.to_s, name: day_name, text: day_name }
    end.to_json
  end
end
