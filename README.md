# hive-runner

[![Join the chat at https://gitter.im/bbc/hive-runner](https://badges.gitter.im/bbc/hive-runner.svg)](https://gitter.im/bbc/hive-runner?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Run automated jobs on devices

## Quick start

Install the hive-runner gem and set up your hive:

    gem install hive-runner
    hive_setup my_hive

Follow the configuration instructions and, in particular, ensure that the
`HIVE_CONFIG` variable is set.

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

## Setting up a new Hive Runner

Check out the Hive Runner from Github:

    # Using HTTPS
    git clone https://github.com/bbc-test/hive-runner
    # ... or using SSH
    git clone ssh@github.com:bbc-test/hive-runner
    # Ensure ruby gems are installed
    cd hive-runner
    bundle install

Configure the hive, either by editing the default configuration file,
`hive-runner/config/hive-runner.yml`, or creating a separate configuration
file in a separate location (recommended) and ensuring that the `HIVE_CONFIG`
environment variable is set correctly:

    echo export HIVE_CONFIG=/path/to/hive-config-directory >> ~/.bashrc

See the "Configuration file" above for details.

Start the Hive Runner:

    ./bin/hived start

Ensure that your Hive Runner is running and that your workers have started:

    ./bin/hived status
