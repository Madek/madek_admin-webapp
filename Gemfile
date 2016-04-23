eval_gemfile Pathname(File.dirname(File.absolute_path(__FILE__))).join('datalayer', 'Gemfile')

gem 'uglifier', '>= 1.3.0'
gem 'therubyracer', platforms: :ruby

# Webserver
gem 'puma'

# API
gem 'responders'

# FRONTEND
gem 'bootstrap-sass'
gem 'haml-rails'
gem 'sass'
gem 'sass-rails', '~> 5.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'kramdown'

# Use jquery as the JavaScript library
gem 'jquery-rails'

# rest
gem 'bcrypt-ruby'
gem 'pundit'
gem 'cider_ci-open_session', '>= 1.0.0', '< 2.0.0'
gem 'kaminari'
gem 'inshape', '>= 1.0.1', '< 2.0'

####################################################################
# TEST or DEVELOPMENT only
#####################################################################

gem 'better_errors', platform: :mri, group: [:development]
gem 'binding_of_caller', platform: :mri, group: [:development]
gem 'capybara', '~> 2.4', group: [:test]
gem 'meta_request', group: [:development]
gem 'flamegraph', group: [:development], platform: :mri # for mini-profiler
gem 'poltergeist', group: [:test, :development, :personas]
gem 'quiet_assets', group: [:development]
gem 'rack-mini-profiler', group: [:development, :production]
gem 'rest-client', group: [:test, :development, :personas]
gem 'ruby-prof', group: [:development], platform: :mri
gem 'selenium-webdriver', group: [:test]

