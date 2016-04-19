# encoding: utf-8

FactoryGirl.define do
  factory :absence_justification do
    absence_date  '2015-01-02'
    absence_date_end  '2015-01-02'
    justification 'Consulta médica'

    association :teacher, factory: :teacher
    student
  end
end
