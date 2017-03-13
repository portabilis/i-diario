class ResourceDestroyer
  attr_reader :error_message

  def destroy(resource)
    begin
      resource.destroy
    rescue ActiveRecord::DeleteRestrictionError => e
      association = I18n.t("activerecord.models.#{e.message.match(/of dependent ([a-z_]+)/)[1].singularize}.other").downcase
      @error_message = "Não é possível excluir o registro pois existem #{association} dependentes"
    end

    self
  end

  def has_error?
    !@error_message.blank?
  end
end
