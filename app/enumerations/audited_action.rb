class AuditedAction < EnumerateIt::Base
  associate_values :update, :create, :destroy
end
