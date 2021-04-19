require 'net/https'

class RecaptchaVerifier
  RECAPTCHA_MINIMUM_SCORE = 0.5

  def initialize(token, remote_ip, username)
    @token = token
    @remote_ip = remote_ip
    @username = username
  end

  def self.verify?(token, remote_ip, username)
    new(token, remote_ip, username).verify?
  end

  def verify?
    return true if secret_key.blank?

    if !response['success'] || response['score'] <= minimum_score
      Rails.logger.info("LOG: RecaptchaVerifier#verify? - remote_ip: #{@remote_ip}")
      Rails.logger.info("LOG: RecaptchaVerifier#verify? - username: #{@username}")
      Rails.logger.info("LOG: RecaptchaVerifier#verify? - response['score']: #{response['score']}")
      Rails.logger.info("LOG: RecaptchaVerifier#verify? - minimum_score: #{minimum_score}")
    end

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
