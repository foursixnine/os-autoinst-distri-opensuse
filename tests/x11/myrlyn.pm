use base "x11test";
use strict;
use warnings;
use testapi;

sub run {
    ensure_installed('myrlyn');
    x11_start_program('myrlyn');
    send_key 'alt-f4';
}

1;
