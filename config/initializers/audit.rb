module Audited
  class Audit < ::ActiveRecord::Base
    private

    def set_version_number
      0
    end
  end
end
