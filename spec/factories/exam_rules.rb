FactoryGirl.define do
  factory :exam_rule do
    sequence(:api_code) { |n| n }
    score_type     ScoreTypes::NUMERIC
    frequency_type FrequencyTypes::GENERAL
    opinion_type   OpinionTypes::DONT_USE
  end
end