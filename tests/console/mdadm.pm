# SUSE's openQA tests
#
# Copyright 2018-2020 SUSE LLC
# SPDX-License-Identifier: FSFAP

# Package: mdadm
# Summary: mdadm test, run script creating RAID 0, 1, 5, re-assembling and replacing faulty drive
# - Fetch mdadm.sh from datadir
# - Execute bash mdadm.sh |& tee mdadm.log
# - Upload mdadm.log
# Maintainer: QE Core <qe-core@suse.de>

use Mojo::Base 'consoletest';
use testapi;
use Utils::Logging 'save_and_upload_log';
use serial_terminal 'select_serial_terminal';
use package_utils 'install_package';
use version_utils 'is_sle';
use power_action_utils qw(power_action);

# this is so the kernel stuff works
use Utils::Backends;
use kernel;
use utils qw(zypper_ar zypper_call zypper_search reconnect_mgmt_console);

sub run {
    my ($self) = @_;
    # Use root-console for KOTD installation on svirt instead of root-sut-serial poo#54275
    # is_svirt_except_s390x ? select_console('root-console') : select_serial_terminal;
    select_serial_terminal;
    my $project = get_var("BS_PROJECT");
    $project =~ s#:(?!//)#:/#g;
    my $url = (is_sle) ? "http://download.suse.de/ibs/" : "http://download.opensuse.org/repositories/";
    my $kotd_repo = "$url$project/standard";    # get_required_var('KOTD_REPO');
    zypper_ar($kotd_repo, name => 'KOTD', priority => 90, no_gpg_check => 1);
    remove_kernel_packages;
    zypper_ar($kotd_repo, name => 'KOTD', priority => 90, no_gpg_check => 1);
    zypper_call("in -lr KOTD kernel-default");
    my $packlist = zypper_search('-sx kernel-default');
    die 'More than one kernel was installed'
      unless 1 == scalar grep { $$_{status} =~ m/^i/ } @$packlist;

    if (is_remote_backend) {
        record_info 'Remote', 'Reconnect mgmt console';
        reconnect_mgmt_console();
    }

    # Reboot system after kernel installation
    power_action('reboot');
    $self->wait_boot(bootloader_time => 300);

    select_serial_terminal;


    install_package('mdadm expect', trup_reboot => 1);

    record_info("mdadm build", script_output("rpm -q --qf '%{version}-%{release}' mdadm"));

    assert_script_run 'wget ' . data_url('qam/mdadm.sh');

    my $timeout = 600;
    if (is_sle('<15')) {
        if (script_run('time -p bash mdadm.sh |& tee mdadm.txt; if [ ${PIPESTATUS[0]} -ne 0 ]; then false; fi', $timeout)) {
            record_soft_failure 'bsc#1105628';
            assert_script_run 'time -p bash mdadm.sh |& tee mdadm.txt; if [ ${PIPESTATUS[0]} -ne 0 ]; then false; fi', $timeout;
        }
    }
    else {
        assert_script_run "rpm -q suse-module-tools";
        script_run qq/rpm -ql suse-module-tools | grep 65-md-raid-properties.rules/;
        # assert_script_run qq/udevadm control --reload-rules/;
        # assert_script_run qq/udevadm trigger/;
        assert_script_run qq/time -p timeout \$(($timeout-10)) bash mdadm.sh |& tee mdadm.txt; if [ \${PIPESTATUS[0]} -ne 0 ]; then false; fi/, $timeout;

    }
    upload_logs 'mdadm.txt';
}

sub post_fail_hook {
    # select_serial_terminal;
    select_console "root-console";
    upload_logs 'mdadm.txt';
    save_and_upload_log('journalctl --no-pager -ab -o short-precise', 'journal.txt');
    power_action('reboot', textmode => 1);
}

1;
