# Be sure to restart your server when you modify this file.

Rails.application.config.to_prepare do
  Rails.application.config.session_store :cookie_store, key: Madek::Constants::AdminWebapp::SESSION_NAME
end