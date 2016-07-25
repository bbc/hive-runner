# hive-runner

Run automated jobs on devices

## Requirements

* Ruby (we currently use 2.2.0)
* Linux or OSX
* rvm on OSX (rbenv and others are not currently supported, see: https://waffle.io/bbc/hive-ci/cards/579613e206bf561900851d05)

## Quick start

Install the hive-runner gem and set up your hive:

    gem install hive-runner
    hive_setup my_hive

Follow the configuration instructions.

Start the Hive daemon:

    hived start

Determine the status of the Hive:

    hived status

Stop the Hive:

    hived stop

## Configuration file

Example config file:

    test:
      controllers:
        shell:
          max_workers: 5
          name_stub: SHELL_WORKER
          queues:
            - bash
    
      logging:
        directory: logs
        pids: pids
        main_filename: hive.log
    
      timings:
        worker_loop_interval: 5

### Controllers

The `controllers` section contains details about the controllers to be
used by the hive. The name of each section indicates the controller type. Some
of the fields in each controllers section is common to all controller types
(see below) while some are defined for each specific controller type.

Fields for all controller types are:

| Field             | Content                                   |
|-------------------|-------------------------------------------|
| `max_workers`     | Maximum number of workers to use          |
| `port_range_size` | Number of ports to allocate to the device |
| `name_stub`       | Stub for name of the worker process       |

### Ports

| Field     | Content             |
|-----------|---------------------|
| `minimum` | Minimum port number |
| `maximum` | Maximum port number |

### Logging

| Field           | Content                   |
|-----------------|---------------------------|
| `directory`     | Log file directory        |
| `pids`          | PIDs directory            |
| `main_filename` | Name of the main log file |

### Timings

The `worker_loop_interval` indicates the number of seconds to wait between each
poll of the job queue in the worker loop.

## Shell controller

### Configuration

The shell controller section contains the following additional field:

| Field     | Content                                   |
|-----------|-------------------------------------------|
| `queues`  | Array of job queues for the shell workers |
| `workers` | Number of shell workers to run            |
