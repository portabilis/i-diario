class UnitiesParser
  def self.parse!(configuration)
    new(configuration).parse!
  end

  def initialize(configuration)
    self.configuration = configuration
  end

  def parse!
    build_records api.fetch_all["escolas"]
  end

  protected

  attr_accessor :configuration

  def api
    IeducarApi::Schools.new(configuration.to_api)
  end

  def build_records(collection)
    new_unities = []

    collection.each do |record|
      unless unities.exists?(api_code: record["cod_escola"])
        if record["nome"].present?
          phone = nil
          phone = "(#{record["ddd"]}) #{record["phone"]}" if record["phone"].present?

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

          new_unities << unities.new(
            api: true,
            api_code: record["cod_escola"],
            name: record["nome"],
            phone: phone,
            email: record["email"].try(:strip),
            responsible: record["nome_responsavel"],
            unit_type: UnitTypes::SCHOOL_UNIT,
            address: address
          )
        end
      end
    end

    new_unities
  end

  def format_cep(value)
    return nil if value.blank? || value.strip.blank?

    value = value.strip.gsub(/[^\d+]/, '')

    return nil if value.length != 8

    pre, suf = value.match(/([0-9]{5})([0-9]{3})/).captures

    "#{pre}-#{suf}"
  end

  def unities(klass = Unity)
    klass
  end
end
