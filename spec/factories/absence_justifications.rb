# encoding: utf-8

FactoryGirl.define do
  factory :absence_justification do
    absence_date  '2015-01-02'
    justification 'Consulta médica'

    association :author, factory: :user
    student
  end
end