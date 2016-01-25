source 'https://rubygems.org'

gem 'rails', '4.2.5'
gem 'uglifier', '>= 1.3.0'
gem 'therubyracer', platforms: :ruby

# Webserver
gem 'puma'

# API
gem 'responders'

# DATABASE
gem 'activerecord-jdbcpostgresql-adapter', platform: :jruby
gem 'jdbc-postgres', platform: :jruby
gem 'pg', platform: :mri
gem 'pg_tasks', '>= 1.3.3', '< 2.0.0'

# ZHDK-INTEGRATION
gem 'madek_zhdk_integration', git: 'https://github.com/madek/madek-zhdk-integration.git', ref: '08d45400baa15ffe94c5bca4fadfd95b5ccea8f1'
gem 'textacular', git: 'https://github.com/DrTom/textacular.git'

# FRONTEND
gem 'bootstrap-sass'
gem 'haml-lint', '~> 0.10.0'
gem 'haml-rails'
gem 'sass'
gem 'sass-rails', '~> 5.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'kramdown'

# Use jquery as the JavaScript library
gem 'jquery-rails'

# rest
gem 'pundit'
gem 'chronic_duration'
gem 'cider_ci-open_session', '>= 1.0.0', '< 2.0.0'
gem 'rails_config', git: 'https://github.com/DrTom/rails_config.git', ref: 'master'
gem 'bcrypt', '~> 3.1.7'
gem 'kaminari'
gem 'uuidtools'
gem 'inshape', '>= 1.0.1', '< 2.0'

####################################################################
# TEST or DEVELOPMENT only
#####################################################################

gem 'better_errors', platform: :mri, group: [:development]
gem 'binding_of_caller', platform: :mri, group: [:development]
gem 'capybara', '~> 2.4', group: [:test]
gem 'factory_girl', group: [:test, :development, :personas]
gem 'faker', group: [:test, :development, :personas]
gem 'meta_request', group: [:development]
gem 'flamegraph', group: [:development], platform: :mri # for mini-profiler
gem 'poltergeist', group: [:test, :development, :personas]
gem 'pry', group: [:test, :development]
gem 'pry-nav', group: [:test, :development]
gem 'pry-rails', group: [:development]
gem 'quiet_assets', group: [:development]
gem 'rack-mini-profiler', group: [:development, :production]
gem 'rest-client', group: [:test, :development, :personas]
gem 'rspec-rails', '~> 3.1', group: [:test, :development]
gem 'rubocop', '= 0.29.1', require: false
gem 'ruby-prof', group: [:development], platform: :mri
gem 'selenium-webdriver', group: [:test]

gem 'cider_ci-support', '~> 3.0.0', group: [:development, :test]
