class IeducarApiConfiguration < ActiveRecord::Base
  validates :url, :token, :secret_token, :unity_code, presence: true
  validates :url, uri: { protocols: %w(http https), message: :invalid_url }, allow_blank: true

  def self.current
    self.first.presence || new
  end
end
