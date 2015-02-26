# hive-runner

Run automated jobs on devices

## Quick start

Start the Hive daemom:

    bundle exec ./bin/hived start

Determine the status of the Hive:

    bundle exec ./bin/hived status

Stop the Hive:

    bundle exec ./bin/hived stop

By default, the Hive will use the configuration in `config/hive-runner.yml`. To
use a different file set the environment variable `HIVE_CONFIG`:

    export HIVE_CONFIG=/path/to/hive-config-file.yml
    bundle exec ./bin/hived start

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

| Field         | Content                             |
|---------------|-------------------------------------|
| `max_workers` | Maximum number of workers to use    |
| `name_stub`   | Stub for name of the worker process |

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

| Field    | Content                                   |
|----------|-------------------------------------------|
| `queues` | Array of job queues for the shell workers |

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

    echo HIVE_CONFIG=/path/to/hive-runner.yml >> ~/.bashrc

See the "Configuration file" above for details.

Start the Hive Runner:

    bundle exec ./bin/hived start

Ensure that your Hive Runner is running and that your workers have started:

    bundle exec ./bin/hived status
