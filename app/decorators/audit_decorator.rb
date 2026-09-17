class AuditDecorator
  def initialize(record)
    self.record = record
  end

  delegate :action, :audited_changes, :auditable, :user, :created_at, to: :record

  def human_attribute_name(field)
    klass.human_attribute_name field
  end

  def klass
    @klass ||= record.auditable_type.constantize
  end

  def enumeration?(field)
    enumeration(field).present?
  end

  def enumeration(field)
    klass.enumerations[field]
  end

  def enumeration_t(field, value)
    enumeration(field).t value
  end

  def parse(field, values, position)
    value = if values.is_a?(Array)
              values.send(position)
            else
              values
            end

    relation = field.to_s.gsub(/_id/, '').to_sym
    association = klass.reflect_on_association(relation)

    if enumeration?(field)
      enumeration_t field, value
    elsif value == false || value == true
      I18n.t "boolean.#{value}"
    elsif value.is_a?(Date) || value.is_a?(Time)
      I18n.l value
    elsif field == :encrypted_password
      "*********"
    elsif field.match(/_id/) && association.present?
      # Sometimes the record used in the relation doesn't exist anymore
      begin
        class_name = if association.try(:class_name)
          association.class_name
        else
          relation
        end

        sanitize_html(class_name.to_s.constantize.find(value).to_s)
      rescue
        value
      end
    else
      sanitize_html(value)
    end
  end

  protected

  attr_accessor :record

  private

  # Os valores de texto livre e de campos rich-text (Summernote) aparecem no histórico
  # renderizados com `raw`. Sanitiza na saída mantendo só a formatação básica, para que
  # `<script>`/`<img onerror>` colados no editor não executem ao abrir o histórico.
  #
  # O `to_s` dos registros associados passa pelo mesmo caminho: descrição de avaliação e
  # nome de turma são texto livre gravado pelo usuário e caem no mesmo `raw`.
  #
  # A allowlist é a mesma que o editor aplica no cliente (`app/assets/javascripts/summernote.js`).
  def sanitize_html(value)
    return value unless value.is_a?(String)

    ApplicationController.helpers.sanitize(value, tags: %w[div p b i u br], attributes: [])
  end
end
