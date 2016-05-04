class AvaliationExemption < ActiveRecord::Base
  belongs_to :avaliation
  belongs_to :student

  audited
  has_associated_audits

  include Audit

  delegate :unity_id, to: :avaliation, prefix: false, allow_nil: true
end
