require 'spec_helper_lite'

require 'active_model'
Dir['app/validators/*.rb'].each {|file| require file }
require 'shoulda/matchers'
require 'support/matchers/validate_date_of_matcher'

include Shoulda::Matchers::ActiveModel
