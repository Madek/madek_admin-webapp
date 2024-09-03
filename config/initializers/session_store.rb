# Be sure to restart your server when you modify this file.
require 'madek/constants/admin_webapp'

Rails.application.config.session_store :cookie_store, key: Madek::Constants::AdminWebapp::SESSION_NAME
