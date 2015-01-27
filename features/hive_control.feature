Feature: Hive control
  As a hive administrator
  I want to start and stop a hive

  Scenario: Starting a hive
    When I start the runner
    Then the runner is running
    
  Scenario: Stopping a hive
    Given The runner has been started
    When I stop the runner
    Then the runner is not running
    
  Scenario: Starting a shell hive
    Given hive is configured to use 1 shell worker(s)
    When I start the runner
    Then the runner loads the shell controller
    And 1 shell worker(s) are running
    
  Scenario: Starting a hive with multiple shell workers
    Given hive is configured to use 2 shell worker(s)
    When I start the runner
    Then the runner loads the shell controller
    And 2 shell worker(s) are running

  Scenario: Stopping a hive
    Given hive is configured to use 1 shell worker(s)
    And The runner has been started
    When I stop the runner
    Then the runner is not running
    And 0 shell worker(s) are running
