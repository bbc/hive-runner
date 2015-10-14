#!/usr/bin/env bash

# Concatinate $RETRY_URNS environment variable array into string
function retry_args {
  echo -n ${RETRY_URNS[*]}
}

# Concatinate $TEST_NAMES into cucumber args
function cucumber_testname_args {
  for TEST_NAME in "${TEST_NAMES[@]}"
  do
    echo -n "-n '^$TEST_NAME\$' "
  done
}
