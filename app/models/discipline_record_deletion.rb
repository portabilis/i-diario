# frozen_string_literal: true

class DisciplineRecordDeletion < ApplicationRecord
  has_many :discipline_record_deletion_postings, dependent: :destroy

  has_enumeration_for :status,
                      with: DisciplineRecordDeletionStatus,
                      create_helpers: true,
                      create_scopes: true

  validates :filters, presence: true

  def mark_with_error!(message)
    update!(
      status: DisciplineRecordDeletionStatus::ERROR,
      error_message: message
    )
  end

  def mark_as_completed!(total)
    update!(
      status: DisciplineRecordDeletionStatus::COMPLETED,
      total_deleted: total
    )
  end
end
