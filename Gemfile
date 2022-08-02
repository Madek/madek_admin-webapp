eval_gemfile Pathname(File.dirname(File.absolute_path(__FILE__))).join('datalayer', 'Gemfile')

ruby '2.7.6'

# Webserver
gem 'puma'

# API
gem 'responders'

# FRONTEND
gem 'bootstrap-sass'
gem 'haml-rails'
gem 'sass'
gem 'sass-rails', '~> 5.0'
gem 'kramdown'
gem 'jquery-rails'


# rest
gem 'pundit'
gem 'cider_ci-open_session', '>= 1.0.0', '< 2.0.0'
gem 'kaminari'
gem 'sys-filesystem', '>= 1.4.3', require: false


####################################################################
# TEST or DEVELOPMENT only
#####################################################################

# gem 'better_errors', group: [:development]
gem 'binding_of_caller', group: [:development]
gem 'capybara', '~> 2.18', group: [:test]
gem 'ffi', '>= 1.15.5', group: [:test, :development]
gem 'poltergeist', group: [:test, :development, :personas]
gem 'rest-client', group: [:test, :development, :personas]
gem 'ruby-prof', group: [:development]
gem 'selenium-webdriver', group: [:test]
gem 'rails-controller-testing', group: :test
