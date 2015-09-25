Gem::Specification.new do |s|
  s.name        = 'hive-runner'
  s.version     = '1.2.1'
  s.date        = Time.now.strftime("%Y-%m-%d")
  s.summary     = 'Hive Runner'
  s.description = 'Core component of the Hive CI runner'
  s.authors     = ['Joe Haig']
  s.email       = 'joe.haig@bbc.co.uk'
  s.files       = Dir['README.md', 'lib/**/*.rb']
  s.executables = ['hived', 'start_hive', 'hive_setup']
  s.homepage    = 'https://github.com/bbc/hive-runner'
  s.license     = 'MIT'
  s.add_runtime_dependency 'chamber', ['~> 2.7']
  s.add_runtime_dependency 'macaddr', ['~> 1.7']
  s.add_runtime_dependency 'activerecord', ['~> 4.2']
  s.add_runtime_dependency 'mono_logger', ['~> 1.1']
  s.add_runtime_dependency 'daemons', ['~> 1.2']
  s.add_runtime_dependency 'terminal-table', ['~> 1.4']

  # These will be added to the Gemfile by hive_setup until they are added to
  # rubygems
  #s.add_runtime_dependency 'hive-messages', ['~> 0.4']
  #s.add_runtime_dependency 'code_cache', ['~> 0.1']
  #s.add_runtime_dependency 'devicedb_comms', ['>= 0.15']
  #s.add_runtime_dependency 'res'
end
