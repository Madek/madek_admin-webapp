require File.expand_path('../boot', __FILE__)
#$:.push File.expand_path('../../engines/datalayer/lib', __FILE__)

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MadekAdmin
  class Application < Rails::Application
    # Use the responders controller from the responders gem
    config.app_generators.scaffold_controller :responders_controller
    config.responders.flash_keys = [ :success, :error ]

    config.active_record.timestamped_migrations = false
    config.active_record.record_timestamps = false
    config.active_record.raise_in_transactional_callbacks = true
    config.active_record.disable_implicit_join_references = true

    config.autoload_paths += [
      Rails.root.join('app', 'api'),
      Rails.root.join('app', 'views'),
      Rails.root.join('lib')
    ]

    config.paths["db/migrate"] << \
      Rails.root.join('datalayer', 'db', 'migrate')

    config.paths['config/initializers'] <<  \
      Rails.root.join('datalayer', 'initializers')

    config.autoload_paths += [
      Rails.root.join('datalayer', 'lib'),
      Rails.root.join('datalayer', 'app', 'models'),
      Rails.root.join('datalayer', 'app', 'lib'),
    ]

    config.logger = ActiveSupport::Logger.new(STDOUT)

    # configure logging
    if ENV['RAILS_LOG_LEVEL'].present?
      config.log_level = ENV['RAILS_LOG_LEVEL']
    else
      config.log_level = :info
    end
    config.log_tags = [->(req) { Time.now.strftime('%T') }, :port, :remote_ip]


    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.consider_all_requests_local = false

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    config.i18n.enforce_available_locales = false
    config.i18n.available_locales = [:de, :en]

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en
  end
end
