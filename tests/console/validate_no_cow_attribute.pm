# SUSE's openQA tests
#
# Copyright © 2019 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved. This file is offered as-is,
# without any warranty.

# Summary: Validation module to check the following:
#
# 1. Verify the certain subvolumes should have No_Cow attribute.
#    Requires 'test_data->{subvolume}->{no_cow}' with the list of subvolumes
#    to be specified in yaml scheduling file.
#
# 2. Verify the certain subvolumes should NOT have No_Cow attribute.
#    Requires 'test_data->{subvolume}->{cow}' with the list of subvolumes
#    to be specified in yaml scheduling file.
#
# Maintainer: Oleksandr Orlov <oorlov@suse.de>

use base "consoletest";
use strict;
use warnings;
use testapi;
use scheduler 'get_test_data';
use Test::Assert ':all';

sub run {
    my $test_data = get_test_data();

    select_console('root-console');

    record_info('Test #1', "Verify the certain subvolumes should have No_COW attibute.");
    foreach (@{$test_data->{subvolume}->{no_cow}}) {
        my $lsattr = get_lsattr_for_subvolume($_);
        assert_true($lsattr =~ /No_COW/i,
            "No_COW attribute is NOT found for $_.\n
            The output of 'lsattr -ld $_:\n$lsattr");
    }

    record_info('Test #2', "Verify the certain subvolumes should NOT have No_COW attribute.");
    foreach (@{$test_data->{subvolume}->{cow}}) {
        my $lsattr = get_lsattr_for_subvolume($_);
        assert_false($lsattr =~ /No_COW/i,
            "No_COW attribute is found for $_, though the subvolume should not has it.\n
            The output of 'lsattr -ld $_:\n$lsattr");
    }

}

sub get_lsattr_for_subvolume {
    return script_output("lsattr -ld $_");
}

1;
