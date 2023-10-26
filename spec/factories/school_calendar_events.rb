FactoryGirl.define do
  factory :school_calendar_event do
    school_calendar

    description { Faker::Lorem.unique.sentence }
    legend { ('A'..'Z').to_a.delete_if { |legend| ['F', 'N'].include?(legend) }[rand(24)] }
    start_date { Date.current.beginning_of_year }
    end_date { Date.current.end_of_year }
    event_type { EventTypes.to_a.sample[1] }
    coverage { EventCoverageType.to_a.sample[1] }
  end
end
