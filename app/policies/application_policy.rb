class ApplicationPolicy
  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    @user.can_show?(feature_name)
  end

  def show?
    index?
  end

  def history?
    show?
  end

  def create?
    @user.can_change?(feature_name)
  end

  def new?
    create?
  end

  def update?
    @user.can_change?(feature_name)
  end

  def edit?
    update?
  end

  def destroy?
    update?
  end

  def permitted_attributes
    []
  end

  protected

  attr_reader :user, :record

  # Overwrite when necessary
  def feature_name
    klass = if record.respond_to?(:model_name)
      record.model_name
    elsif record.class.respond_to?(:model_name)
      record.class.model_name
    end

    klass.to_s.underscore.pluralize
  end
end

