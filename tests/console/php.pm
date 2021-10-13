# SUSE's openQA tests
#
# Copyright 2017-2021 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Package: php7 php-json
# Summary: Simple PHP7 code hosted locally
#   This test requires the Web and Scripting module on SLE.
# - Setup apache2 to use php7 modules
# - Run "curl http://localhost/index.php", check output for "PHP Version 7"
# Maintainer: Ondřej Súkup <osukup@suse.cz>


use base "consoletest";
use strict;
use warnings;
use utils;
use testapi;
use apachetest qw(setup_apache2 get_php_version get_php_mode);

sub run {
    my $self = shift;
    $self->select_serial_terminal;

    my $selected_php = get_php_version;
    setup_apache2(mode => get_php_mode);
    assert_script_run('curl http://localhost/index.php | tee /tmp/tests-console-php7.txt');

    # test function provided by external module (php-json RPM)
    zypper_call 'in php-json';
    assert_script_run('php -r \'echo json_encode(array("foo" => true))."\\n";\' | grep :true');

    # test reading file
    assert_script_run('php -r \'echo readfile("/etc/hosts")."\\n";\' | grep localhost');
}
1;
