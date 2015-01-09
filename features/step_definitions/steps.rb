Before do
  `bundle exec ./bin/hived stop`
  sleep 1
end

After do
  `bundle exec ./bin/hived stop`
  #`killall WORKER`
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
  expect(`bundle exec ./bin/hived status`).to match(/: running \[pid/)
end

Then(/^the runner is not running$/) do
  # TODO: Capture the stderr
  # expect(`bundle exec ./bin/hived status`).to match(/: no instances running/)
  expect(`bundle exec ./bin/hived status`).to match(/^$/)
end

Given(/^hive is configured to use a shell worker$/) do
  ENV['HIVE_CONFIG'] = File.expand_path('../../configurations/one_shell_worker.yml', __FILE__)
end

Then(/^the runner loads the shell controller$/) do
  expect(`bundle exec ./bin/hived status`).to match(/Using shell controller/)
end

Then(/^the shell worker is running$/) do
  expect(`bundle exec ./bin/hived status`).to match(/- shell worker \[pid/)
end

Given(/^hive is configured to use (\d+) shell workers$/) do |arg1|
  ENV['HIVE_CONFIG'] = File.expand_path("../../configurations/#{arg1}_shell_workers.yml", __FILE__)
end

Then(/^(\d+) shell worker\(s\) are running$/) do |arg1|
  expect(`ps aux | grep SHELL_WORKER | grep -v grep | wc -l`.to_i).to be arg1.to_i
end

Given(/^a hive is running with a shell worker$/) do
  pending # express the regexp above with the code you wish you had
end

Then(/^the runner process terminates$/) do
  pending # express the regexp above with the code you wish you had
end

Then(/^the shell worker terminates$/) do
  pending # express the regexp above with the code you wish you had
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
