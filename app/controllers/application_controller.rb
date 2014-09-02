class ApplicationController < ActionController::Base
  include Pundit
  around_action :handle_customer

  respond_to :html, :json

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  protected
  attr_reader :current_user # up to configure devise

  def policy(record)
    Pundit::PolicyFinder.new(record).policy!.new(current_user, record)
  end
  helper_method :policy

  def handle_customer(&block)
    entity = Entity.find_by(domain: request.host)
    entity.using_connection(&block)
  end
end
