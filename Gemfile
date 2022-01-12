# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

ruby '3.1.0'

gem 'clamp' # Arke::Command
gem 'em-http-request' # Arke::Exchange::Sources
gem 'em-synchrony' # Arke::Reactor
gem 'faraday' # Arke::Reactor
gem 'faraday_middleware' # Arke::Reactor
gem 'faye-websocket' # Arke::Exchange::Sources
gem 'json' # Arke::Exchange
gem 'pry' # Arke::Command::Console
gem 'rbtree' # Arke::Orderbook
gem 'tty-table' # Arke::Orderbook

group :development do
  gem 'overcommit'
  gem 'rubocop'
end

group :development, :test do
  gem 'rspec'
  gem 'simplecov'
  gem 'simplecov-rcov'
  gem 'webmock'
end
