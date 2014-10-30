class WeekdaysDecorator
  def self.checkbox_collection
    I18n.t('date.day_names').each_with_index.map do |obj, index|
      OpenStruct.new({weekday: obj, id: index.to_s})
    end
  end
end
