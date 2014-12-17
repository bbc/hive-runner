Feature: Shell Worker
  As a tester
  I want my shell tests to be picked up and executed
  
  Scenario: Subscribing to queues
    Given the shell worker is configured to use queues 'shell_queue_one' and 'shell_queue_two'
    When the shell worker is started
    Then the shell worker polls queue 'shell_queue_one' and 'shell_queue_two'
