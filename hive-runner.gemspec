Gem::Specification.new do |s|
  s.name        = 'hive-runner'
  s.version     = '2.0.7'
  s.date        = Time.now.strftime("%Y-%m-%d")
  s.summary     = 'Hive Runner'
  s.description = 'Core component of the Hive CI runner'
  s.authors     = ['Joe Haig']
  s.email       = 'joe.haig@bbc.co.uk'
  s.files       = Dir['README.md', 'lib/**/*.rb', 'scripts/hive-script-helper.sh']
  s.executables = ['hived', 'start_hive', 'hive_setup']
  s.homepage    = 'https://github.com/bbc/hive-runner'
  s.license     = 'MIT'
  s.add_runtime_dependency 'chamber', '~> 2.7'
  s.add_runtime_dependency 'macaddr', '~> 1.7'
  s.add_runtime_dependency 'activerecord', '~> 4.2'
  s.add_runtime_dependency 'mono_logger', '~> 1.1'
  s.add_runtime_dependency 'daemons', '~> 1.2'
  s.add_runtime_dependency 'terminal-table', '~> 1.4'
  s.add_runtime_dependency 'res', '~> 1.0'
  s.add_runtime_dependency 'hive-messages', '>= 1.0.3', '< 1.1'
  s.add_runtime_dependency 'devicedb_comms', '~> 0.1'
  s.add_runtime_dependency 'mind_meld', '>= 0.0.6', '< 0.1'
  s.add_runtime_dependency 'code_cache', '~> 0.2'
  s.add_runtime_dependency 'sys-uname', '~> 1.0'
  s.add_development_dependency 'simplecov', '~> 0.10'
  s.add_development_dependency 'rspec', '~> 3.3'
  s.add_development_dependency 'rubocop', '~> 0.34'
  s.add_development_dependency 'webmock', '~> 1.21'
end
