## Copyright 2026 SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

# Summary: Installs the system using agama cli
# Maintainer: Santiago Zarate santiago.zarate@suse.com

use Mojo::Base 'Yam::Agama::agama_base';
use testapi;

sub run {
    my ($self) = @_;
    assert_script_run 'agama questions mode non-interactive';
    assert_script_run 'agama install', 3600;

    $self->upload_agama_logs();

    enter_cmd 'agama finish';
}

1;
