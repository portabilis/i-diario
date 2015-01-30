class UnitiesSynchronizer
  def self.synchronize!(synchronization)
    new(synchronization).synchronize!
  end

  def initialize(synchronization)
    self.synchronization = synchronization
  end

  def synchronize!
    create_records api.fetch_all["escolas"]
  end

  protected

  attr_accessor :synchronization

  def api
    IeducarApi::Schools.new(synchronization.to_api)
  end

  def create_records(collection)
    ActiveRecord::Base.transaction do
      collection.each do |record|
        unless unities.find_by(api_code: record["cod_escola"])
          if record["nome"].present?
            phone = nil
            phone = "(#{record["ddd"]}) #{record["phone"]}" if record["phone"].present?

            address = nil

            if record["cep"].present? && record["numero"].present?
              address = Address.new(
                street: record["logradouro"],
                zip_code: format_cep(record["cep"]),
                number: record["numero"],
                complement: record["complemento"],
                neighborhood: record["bairro"],
                city: record["municipio"],
                state: record["uf"].downcase,
                country: "Brasil"
              )
            end

            begin
            unities.create!(
              api: true,
              api_code: record["cod_escola"],
              name: record["nome"],
              phone: phone,
              email: record["email"].try(:strip),
              responsible: record["nome_responsavel"],
              author: author,
              unit_type: UnitTypes::SCHOOL_UNIT,
              address: address
            )
            rescue Exception => e
              raise "#{e.message} #{record["email"]}.."
            end
          end
        end
      end
    end
  end

  def format_cep(value)
    return nil if value.blank? || value.strip.blank?

    pre, suf = value.strip.gsub(/[^\d+]/, '').match(/([0-9]{5})([0-9]{3})/).captures

    "#{pre}-#{suf}"
  end

  def unities(klass = Unity)
    klass
  end

  def author
    @user ||= User.admin.first
  end
end
