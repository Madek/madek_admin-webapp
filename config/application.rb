require_relative "boot"
require_relative('../datalayer/lib/madek/middleware/audit.rb')
$:.push File.expand_path('../../datalayer/lib', __FILE__)

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MadekAdmin
  class Application < Rails::Application
    config.load_defaults 6.1
    config.autoloader = :classic

    # Use the responders controller from the responders gem
    config.app_generators.scaffold_controller :responders_controller
    config.responders.flash_keys = [ :success, :error ]

    config.active_record.timestamped_migrations = false
    config.active_record.record_timestamps = false
    config.active_record.yaml_column_permitted_classes = [Time, Rational]

    config.eager_load_paths << Rails.root.join('lib')

    config.paths['db/migrate'] << \
      Rails.root.join('datalayer', 'db', 'migrate')

    config.paths['config/initializers'] <<  \
      Rails.root.join('datalayer', 'initializers')

    config.eager_load_paths += [
      Rails.root.join('datalayer', 'lib'),
      Rails.root.join('datalayer', 'app', 'models', 'concerns'),
      Rails.root.join('datalayer', 'app', 'controllers'),
      Rails.root.join('datalayer', 'app', 'controllers', 'concerns'),
      Rails.root.join('datalayer', 'app', 'models'),
      Rails.root.join('datalayer', 'app', 'lib'),
      Rails.root.join('datalayer', 'app', 'queries'),
    ]

    config.logger = ActiveSupport::Logger.new(STDOUT) unless Rails.env.development?

    # configure logging
    if ENV['RAILS_LOG_LEVEL'].present?
      config.log_level = ENV['RAILS_LOG_LEVEL']
    else
      config.log_level = :info
    end
    config.log_tags = [->(req) { Time.now.strftime('%T') }, :port, :remote_ip]

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2
    config.active_record.belongs_to_required_by_default = false

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.consider_all_requests_local = false

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    config.i18n.enforce_available_locales = false

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en

    config.middleware.insert_before ActionDispatch::ShowExceptions, Madek::Middleware::Audit
  end
end

require 'madek/constants'
