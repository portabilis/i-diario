require 'net/https'

class RecaptchaVerifier
  RECAPTCHA_MINIMUM_SCORE = 0.5

  def initialize(token)
    @token = token
  end

  def self.verify?(token)
    new(token).verify?
  end

  def verify?
    return true if secret_key.blank?

    response['success'] && response['score'] > minimum_score
  end

  private

  def uri
    URI.parse("https://www.google.com/recaptcha/api/siteverify?secret=#{secret_key}&response=#{@token}")
  end

  def response
    @response ||= JSON.parse(Net::HTTP.get_response(uri).body)
  end

  def secret_key
    @secret_key ||= Rails.application.secrets.recaptcha_secret_key
  end

  def minimum_score
    @minimum_score ||= Rails.application.secrets.recaptcha_minimum_score || RECAPTCHA_MINIMUM_SCORE
  end
end
