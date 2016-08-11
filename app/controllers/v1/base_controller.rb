# encoding: utf-8
class V1::BaseController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :configure_permitted_parameters
  skip_before_action :check_for_***REMOVED***
end
