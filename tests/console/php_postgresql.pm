# SUSE's openQA tests
#
# Copyright 2017-2021 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Package: php7 php7-pgsql postgresql*-contrib sudo unzip
# Summary: PHP7 code that interacts locally with PostgreSQL
#   This tests creates a PostgreSQL database and inserts an element.
#   Then, PHP reads the elements and writes a new one in the database.
#   If all succeed, the test passes.
#
#   The test requires the Web and Scripting module on SLE
# - Setup apache2 to use php7 modules
# - Install php7-pgsql postgresql*-contrib sudo
# - Start postgresql service
# - Populate postgresql with test db from data dir
# - Run a select command
# - Setup postgresql (password, access control)
# - Grab php test file from datadir
# - Run "curl --no-buffer http://localhost/test_postgresql_connector.php | grep 'can you read this?'"
# - Run select on database to check inclusion
# - Set PG_OLDEST, PG_LATEST and run a set of tests
#   - Create a new database
#   - Start/Stop/Status a database
#   - Upgrade a postgresql instance
#   - Cleanup database
# - Import and run dvdrental test
# - Cleanup postgresql database
# Maintainer: Ondřej Súkup <osukup@suse.cz>


use base "consoletest";
use strict;
use warnings;
use testapi;
use utils 'zypper_call';
use apachetest;
use Utils::Systemd 'systemctl';

sub run {
    my $self = shift;
    $self->select_serial_terminal;
    # ensure apache2 + php is installed and running
    my $selected_php = get_php_version;
    setup_apache2(mode => get_php_mode);

    # install requirements, all postgresql versions to test db upgrade if there are multiple versions
    zypper_call "in $selected_php-pgsql postgresql*-contrib sudo unzip";

    # start postgresql service
    systemctl 'start postgresql';

    # setup database
    setup_pgsqldb;

    # test itself
    test_pgsql;

    # destroy database
    destroy_pgsqldb;

    # poo#62000
    postgresql_cleanup;
}

1;
