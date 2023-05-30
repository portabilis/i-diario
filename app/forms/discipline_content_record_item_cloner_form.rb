class DisciplineContentRecordItemClonerForm < ApplicationRecord
  has_no_table

  attr_accessor :uuid, :discipline_content_record_cloner_form_id, :classroom_id, :record_date
  belongs_to :discipline_content_record_cloner_form

  validates :classroom_id, :record_date, presence: true
end
