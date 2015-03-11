source 'https://rubygems.org'

group :test do
  gem 'simplecov'
  gem 'rspec'
  gem 'cucumber'
  gem 'rubocop'
  gem 'webmock'
end

gem 'chamber'
gem 'macaddr'
gem 'activerecord'
gem 'sqlite3'
gem 'mono_logger'
gem 'daemons', '>= 1.2.0'
gem 'terminal-table'

gem 'hive-messages', git: 'git@github.com:bbc/hive-messages.git', branch: 'better-results'
gem 'code_cache', git: 'git@github.com:bbc/code_cache.git'
gem 'devicedb_comms', git: 'git@github.com:bbc/devicedb_comms.git'

Dir.glob("plugins/Gemfile.*").each do |gemfile|
  eval File.read(gemfile), nil, gemfile
end
