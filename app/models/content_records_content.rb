class ContentRecordsContent < ApplicationRecord
  include Audit
  audited except: [:content_record_id],
          allow_mass_assignment: true,
          associated_with: [:content_record, :content]

  belongs_to :content_record
  belongs_to :content
end
