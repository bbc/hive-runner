Feature: Hive control
  As a hive administrator
  I want to start and stop a hive
  
  Scenario: Starting a hive
    When I start the runner
    Then the runner starts
    
  Scenario: Starting a shell hive
    Given hive is configured to use a shell worker
    When I start the runner
    Then the runner loads the shell controller
    And the shell worker starts
    
  Scenario: Starting a hive with multiple shell workers
    Given hive is configured to use 2 shell workers
    When I start the runner
    Then the runner loads the shell controller
    And 2 shell workers start

  Scenario: Stopping a hive
    Given a hive is running with a shell worker
    When I stop the runner
    Then the runner process terminates
    And the shell worker terminates
