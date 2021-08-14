module Audit
  def all_audits
    ids = audits.pluck(:id)

    ids = ids.concat(associated_audits.pluck(:id)) if respond_to?(:associated_audits)

    Audited::Audit.where(:id => ids).reorder("id DESC")
  end
end
