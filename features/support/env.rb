Before do
  stub_request(:get, 'devicedb.mock')
  ENV['HIVE_CONFIG'] = create_configuration()
  ENV['HIVE_ENVIRONMENT'] = 'test'
  ENV['HIVE_COMM_PORT'] = '9990'
  `bundle exec ./bin/hived stop`
  sleep 10
end

After do
  `bundle exec ./bin/hived stop`
  sleep 10
end
