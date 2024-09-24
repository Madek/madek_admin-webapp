require_relative "boot"
require_relative('../datalayer/lib/madek/middleware/audit.rb')

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
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MadekAdmin
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    config.responders.flash_keys = [ :success, :error ]

    config.active_record.timestamped_migrations = false
    config.active_record.record_timestamps = false
    config.active_record.yaml_column_permitted_classes = [Time, Rational]

    config.paths['db/migrate'] << \
      Rails.root.join('datalayer', 'db', 'migrate')

    config.paths['config/initializers'] <<  \
      Rails.root.join('datalayer', 'initializers')

    config.eager_load_paths += [
      Rails.root.join('lib'),
      Rails.root.join('datalayer', 'lib'),
      Rails.root.join('datalayer', 'app', 'models', 'concerns'),
      Rails.root.join('datalayer', 'app', 'controllers'),
      Rails.root.join('datalayer', 'app', 'controllers', 'concerns'),
      Rails.root.join('datalayer', 'app', 'models'),
      Rails.root.join('datalayer', 'app', 'lib'),
      Rails.root.join('datalayer', 'app', 'queries'),
    ]

    # configure logging
    if ENV['RAILS_LOG_LEVEL'].present?
      config.log_level = ENV['RAILS_LOG_LEVEL']
    else
      config.log_level = :info
    end
    config.log_tags = [->(req) { Time.now.strftime('%T') }, :port, :remote_ip]

    config.active_record.belongs_to_required_by_default = false

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil
    config.middleware.insert_before ActionDispatch::ShowExceptions, Madek::Middleware::Audit
  end
end
