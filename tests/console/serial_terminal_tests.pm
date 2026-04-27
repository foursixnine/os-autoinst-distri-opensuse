use Mojo::Base 'consoletest';
use testapi;
use serial_terminal 'select_serial_terminal';

sub run {
    select_serial_terminal;

    my $very_long_command = 'echo "';
    $very_long_command .= 'a' x 2048;
    $very_long_command .= '" | wc ';

    record_info("Testing script output");
    my $output = script_output($very_long_command);
    record_info("Output", $output);

    record_info("Testing script_run");
    my $ret = script_run($very_long_command);
    record_info("Return value: $ret");

}

1;
