FactoryGirl.define do
  factory :iep_medication do
    association :iep, factory: :individualized_educational_plan
    name { 'Metilfenidato' }
    dosage { '10 mg' }
    schedule { '07h30' }
  end
end
