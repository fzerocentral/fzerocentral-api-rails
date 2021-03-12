source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
# When upgrading, follow the upgrading steps here:
# https://edgeguides.rubyonrails.org/upgrading_ruby_on_rails.html
gem 'rails', '~> 6.0.1'
# Use postgresql as the database for Active Record
# Changelog: https://github.com/ged/ruby-pg/blob/master/History.rdoc
gem 'pg', '>= 1.1.4', '< 2.0'
# Use Puma as the app server
# Changelog: https://github.com/puma/puma/blob/master/History.md
gem 'puma', '~> 5'
# JSON API helper; e.g. wrapping our data in an object with a 'data' key
# Changelog: https://github.com/rails-api/active_model_serializers/blob/0-10-stable/CHANGELOG.md
gem 'active_model_serializers', '~> 0.10.10'
# Pagination, e.g. of API results. Pagy handles the core pagination
# functionality. api-pagination handles the JSON API side of pagination.
# pagy changelog: https://github.com/ddnexus/pagy/blob/master/CHANGELOG.md
# api-pagination changelog: https://github.com/davidcelis/api-pagination/releases
gem 'pagy', '~> 3.7'
gem 'api-pagination', '~> 4.8.2'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem 'rack-cors'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Load environment variables from a <projectroot>/.env file.
  gem 'dotenv-rails'
end

group :development do
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
