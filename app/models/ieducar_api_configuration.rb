class IeducarApiConfiguration < ActiveRecord::Base
  audited

  include Audit

  has_many :syncronizations, class_name: "IeducarApiSyncronization"

  validates :url, :token, :secret_token, :unity_code, presence: true
  validates :url, uri: { protocols: %w(http https), message: :invalid_url }, allow_blank: true

  def self.current
    self.first.presence || new
  end

  def start_syncronization!(user)
    syncronizations.create!(status: ApiSyncronizationStatus::STARTED, author: user)
  end

  def syncronization_in_progress?
    syncronizations.started.exists?
  end

  def to_api
    {
      url: url,
      access_key: token,
      secret_key: secret_token,
      unity_id: unity_code
    }
  end
end
