Rails.application.config.session_store :redis_session_store, {
  key: 'idiario',
  redis: {
    expire_after: 1.month,
    key_prefix: 'idiario:session:',
    url: Rails.application.secrets[:redis_url] || 'redis://localhost:6379/0'
  }
}
