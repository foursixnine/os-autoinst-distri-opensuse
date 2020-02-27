# SUSE's openQA tests
#
# Copyright © 2009-2013 Bernhard M. Wiedemann
# Copyright © 2012-2018 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: simple mysql server startup test
# - Install mysql
# - Check mysql service status
# - Start mysql
# - Check mysql service status
# Maintainer: Oliver Kurz <okurz@suse.de>

use strict;
use warnings;
use base "consoletest";
use testapi;
use utils;
use registration qw(add_suseconnect_product get_addon_fullname);

sub run {
    select_console 'root-console';
    add_suseconnect_product(get_addon_fullname('serverapp'));
    zypper_call('in mysql');

    if (script_run('grep \'bindir="$basedir/sbin"\' /usr/bin/mysql_install_db') == 0) {
        record_soft_failure 'bsc#1142058';
        assert_script_run 'sed -i \'s|resolveip="$bindir/resolveip"|resolveip="/usr/bin/resolveip"|\' /usr/bin/mysql_install_db';
    }
    systemctl 'status mysql', expect_false => 1, fail_message => 'mysql should be disabled by default';
    systemctl 'start mysql';
    systemctl 'status mysql';
    assert_screen 'test-mysql_srv-1';

    type_string "mysql\n";

    #type into the mysql console
    type_string "connect test;\n
    CREATE TABLE foo (bar varchar(10));\n
    SET SESSION idle_transaction_timeout=2;\n
    BEGIN;\n
    SELECT * FROM foo;\n";
    sleep 3;
    type_string "SELECT * FROM foo;\n";
    type_string "exit\n";
    assert_screen 'mysql-idle-transaction-disconnected';
}

1;
