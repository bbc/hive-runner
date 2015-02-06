Before do
  ENV['HIVE_CONFIG'] = create_configuration()
  ENV['HIVE_ENVIRONMENT'] = 'test'
  ENV['HIVE_COMM_PORT'] = '9990'
  `bundle exec ./bin/hived stop`
  sleep 1
end

After do
  `bundle exec ./bin/hived stop`
  sleep 1
end

Given(/^The runner has been started$/) do
  expect(system('bundle exec ./bin/hived start')).to be true
  sleep 1
end

When(/^I start the runner$/) do
  expect(system('bundle exec ./bin/hived start')).to be true
  sleep 5
end

When(/^I stop the runner$/) do
  expect(system('bundle exec ./bin/hived stop')).to be true
  sleep 1
end

Then(/^the runner is running$/) do
  # TODO: Does this need two checks?
  expect(`bundle exec ./bin/hived status`).to match(/: running \[pid/)
  expect(`ps aux | grep TEST_HIVE | grep -v grep | wc -l`.to_i).to be 1
end

Then(/^the runner is not running$/) do
  # TODO: Does this need two checks?
  # TODO: Capture the stderr
  # expect(`bundle exec ./bin/hived status`).to match(/: no instances running/)
  expect(`bundle exec ./bin/hived status`).to match(/^$/)
  expect(`ps aux | grep TEST_HIVE | grep -v grep | wc -l`.to_i).to be 0
end

Then(/^the runner loads the shell controller$/) do
  expect(`bundle exec ./bin/hived status`).to match(/Using shell controller/)
end

Then(/^the shell worker is running$/) do
  expect(`bundle exec ./bin/hived status`).to match(/- shell worker \[pid/)
end

Given(/^hive is configured to use (\d+) shell worker\(s\)$/) do |arg1|
  ENV['HIVE_CONFIG'] = create_configuration(n_workers: arg1.to_i)
end

Then(/^(\d+) shell worker\(s\) are running$/) do |arg1|
  expect(`ps aux | grep SHELL_WORKER | grep -v grep | wc -l`.to_i).to be arg1.to_i
end

Given(/^the shell worker is configured to use queues 'shell_queue_one' and 'shell_queue_two'$/) do
  pending # express the regexp above with the code you wish you had
end

When(/^the shell worker is started$/) do
  pending # express the regexp above with the code you wish you had
end

Then(/^the shell worker polls queue 'shell_queue_one' and 'shell_queue_two'$/) do
  pending # express the regexp above with the code you wish you had
end

# TODO: Do this a bit better, and perhaps put in a 'helpers' file
def create_configuration(options = {})
  dir = File.expand_path('../../tmp', __FILE__)
  name = File.join(dir, 'settings.yml')
  File.open(name, 'w') do |f|
    f.puts 'test:'
    f.puts '  daemon_name: TEST_HIVE'
    f.puts '  controllers:'
    f.puts '    shell:'
    f.puts "      max_workers: #{options[:n_workers] || 5}"
    f.puts '      name_stub: SHELL_WORKER'
    f.puts '      queues:'
    f.puts '        - test_queue'
    f.puts '  logging:'
    f.puts '    directory: features/tmp'
    f.puts '    pids: features/tmp'
    f.puts '    main_filename: hive.log'
    f.puts '    home_directory: features/tmp'
    f.puts '  timings:'
    f.puts '    worker_loop_interval: 5'
    f.puts '    controller_loop_interval: 5'
    f.puts '  network:'
    f.puts '    scheduler: https://example.co.uk'
    f.puts '    cert: cert.pem'
  end
  dir
end
