# SUSE's openQA tests
#
# Copyright 2025 SUSE LLC
# SPDX-License-Identifier: FSFAP
# Package: sdbootutil
# Summary: Enroll TPM to unlock encrypted disk
# Maintainer: Santiago Zarate <santiago.zarate@suse.com>

use base 'consoletest';
use strict;
use warnings;
use testapi;
use utils;
use power_action_utils 'power_action';

sub run {
    select_console 'root-console';
    my $repo = "https://download.opensuse.org/repositories/home:/jsegitz:/branches:/security:/SELinux_1241964/openSUSE_Factory/home:jsegitz:branches:security:SELinux_1241964.repo";
    zypper_ar($repo, priority => 90, no_gpg_check => 1);
    zypper_call("ref");
    zypper_call("in --allow-vendor-change selinux-policy");
    script_run("timeout 1780 restorecon -R /", timeout => 1800);
    script_run_interactive(
        "sdbootutil -vv enroll --method tpm2 |& tee enrollment.log",
        [
            {
                prompt => qr/Password for.*/m,
                string => "$testapi::password\n",
            },
        ],
        60
    );

    upload_logs("enrollment.log");

    set_var("RUNTIME_TPM_ENROLLED", 1);
    power_action('reboot', textmode => 1, keepconsole => 1);
    shift->wait_boot(bootloader_time => 300);
    # since this is a consoletest, allow post_run hook to run freely
    # by switching back to root-console
    select_console 'root-console';
}

1;
