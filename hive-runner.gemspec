Gem::Specification.new do |s|
  s.name        = 'hive-runner'
  s.version     = '2.1.21'
  s.date        = Time.now.strftime("%Y-%m-%d")
  s.summary     = 'Hive Runner'
  s.description = 'Core component of the Hive CI runner'
  s.authors     = ['Joe Haig']
  s.email       = 'joe.haig@bbc.co.uk'
  s.files       = Dir['README.md', 'lib/**/*.rb', 'scripts/hive-script-helper.sh', 'bin/init.d.hived']
  s.executables = ['hived', 'start_hive', 'hive_setup']
  s.homepage    = 'https://github.com/bbc/hive-runner'
  s.license     = 'MIT'
  s.add_runtime_dependency 'chamber', '~> 2.7'
  # Awaiting a fix for this gem
  # See lib/macaddr.rb
  #s.add_runtime_dependency 'macaddr', '~> 1.7'
  s.add_runtime_dependency 'activerecord', '~> 4.2'
  s.add_runtime_dependency 'mono_logger', '~> 1.1'
  s.add_runtime_dependency 'daemons', '~> 1.2'
  s.add_runtime_dependency 'terminal-table', '~> 1.7.1'
  s.add_runtime_dependency 'res', '~> 1.2.17'
  s.add_runtime_dependency 'hive-messages', '~> 1.0', '>=1.0.6'
  s.add_runtime_dependency 'mind_meld', '~> 0.1.12'
  s.add_runtime_dependency 'code_cache', '~> 0.2'
  s.add_runtime_dependency 'sys-uname', '~> 1.0'
  s.add_runtime_dependency 'sys-cpu', '~> 0.7'
  s.add_runtime_dependency 'airbrake-ruby', '~> 1.2.2'
  s.add_development_dependency 'codeclimate-test-reporter', '~> 0.6.0'
  s.add_development_dependency 'simplecov', '~> 0.12'
  s.add_development_dependency 'rspec', '~> 3.3'
  s.add_development_dependency 'rubocop', '~> 0.34'
  s.add_development_dependency 'webmock', '~> 1.21'
end
