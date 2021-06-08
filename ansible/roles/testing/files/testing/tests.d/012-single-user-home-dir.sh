#!/bin/bash
. $(dirname $0)/../assert.sh

### We have an extra home directory for the shiny user
assert_raises "test $(find /home -mindepth 1 -maxdepth 1 -type d | wc -l) -lt 3"
assert_end "Home directory count (<3)"
