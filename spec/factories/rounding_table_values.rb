FactoryGirl.define do
  factory :rounding_table_value do
    rounding_table

    rounding_table_api_code { rounding_table.api_code }
    label { 'A' }
    value { 7 }
    action { RoundingTableAction::NONE }
  end
end
