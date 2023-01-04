ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'

DEFAULT_BROWSER_TIMEOUT = 180 # instead of the default 60

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

ActiveRecord::Migration.check_pending! if defined?(ActiveRecord::Migration)

firefox_bin_path = Pathname.new(`asdf where firefox`.strip).join('bin/firefox').expand_path.to_s
Selenium::WebDriver::Firefox.path = firefox_bin_path

def truncate_tables
  PgTasks.truncate_tables
end

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.infer_base_class_for_anonymous_controllers = true
  config.order = 'random'

  Capybara.register_driver :selenium do |app|
    Capybara::Selenium::Driver.new(
      app,
      browser: :firefox)
  end

  Capybara.register_driver :selenium_ff do |app|
    create_firefox_driver(app, DEFAULT_BROWSER_TIMEOUT)
  end

  Capybara.register_driver :selenium_ff_nojs do |app|
    create_firefox_driver(app, DEFAULT_BROWSER_TIMEOUT,
                          'general.useragent.override' => 'Firefox NOJSPLZ')
  end

  def set_browser(example)
    Capybara.current_driver = \
      case example.metadata[:browser]
      when :firefox then :selenium_ff
      when :firefox_nojs then :selenium_ff_nojs
      else :rack_test
      end
  end

  def maximize_window_if_possible
    if Capybara.current_driver.presence_in %i(selenium_ff selenium_ff_nojs)
      Capybara.page.driver.browser.manage.window.maximize
    end
  end

  config.before(:each) do |example|
    truncate_tables
    PgTasks.data_restore Rails.root.join('db', 'personas.pgbin')
    set_browser(example)
    maximize_window_if_possible
  end

  config.after(:each) do |example|
    unless example.exception.nil?
      take_screenshot
    end
  end

  def take_screenshot(screenshot_dir = nil, name = nil)
    screenshot_dir ||= Rails.root.join('tmp', 'capybara')
    name ||= "screenshot_#{Time.zone.now.iso8601.tr(':', '-')}.png"
    Dir.mkdir screenshot_dir rescue nil
    path = screenshot_dir.join(name)
    case Capybara.current_driver
    when :selenium_ff, :selenium_chrome
      page.driver.browser.save_screenshot(path) rescue nil
    when :poltergeist
      page.driver.render(path, full: true) rescue nil
    else
      Rails
        .logger
        .warn "Taking screenshots is not implemented for \
              #{Capybara.current_driver}."
    end
  end

  # useful for debugging tests:
  # config.after(:each) do |example|
  #   unless example.exception.nil?
  #     binding.pry
  #   end
  # end

end

def create_firefox_driver(app, timeout, profileConfig = {})
  profile = Selenium::WebDriver::Firefox::Profile.new
  profileConfig.each { |k, v| profile[k] = v }
  opts = Selenium::WebDriver::Firefox::Options.new(profile: profile)
  client = Selenium::WebDriver::Remote::Http::Default.new
  client.read_timeout = timeout
  Capybara::Selenium::Driver.new \
    app, browser: :firefox, options: opts, http_client: client
end
