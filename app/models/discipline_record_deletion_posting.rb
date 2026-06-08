# frozen_string_literal: true

class DisciplineRecordDeletionPosting < ApplicationRecord
  belongs_to :discipline_record_deletion

  validates :record_type, presence: true
end
