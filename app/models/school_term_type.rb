class SchoolTermType < ActiveRecord::Base
  has_many :school_term_types_steps, dependent: :destroy
end
