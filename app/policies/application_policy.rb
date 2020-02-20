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

  def form?
    update?
  end

  def save?
    update?
  end

  def edit_multiple?
    update?
  end

  def multiple_classrooms?
    create?
  end

  def create_multiple_classrooms?
    create?
  end

  def create_or_update_multiple?
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
    return record.to_s.underscore if is_a_report?(record)

    klass = if record.respond_to?(:model_name)
      record.model_name
    elsif record.class.respond_to?(:model_name)
      record.class.model_name
    else
      record
    end

    klass.to_s.underscore.pluralize
  end

  private

  def is_a_report?(record)
    record.to_s.respond_to?(:underscore) && record.to_s.underscore.split('_').last.eql?('report')
  end
end
