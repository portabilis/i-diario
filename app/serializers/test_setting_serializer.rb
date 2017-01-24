class TestSettingSerializer < ActiveModel::Serializer
  attributes :id, :exam_setting_type, :average_calculation_type, :number_of_decimal_places
end
