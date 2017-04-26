#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Log::Any '$log';
use File::Temp 'tempfile';

use Test::More qw 'no_plan';                     


BEGIN {
    use_ok ('Log::Any::Adapter::Multiplexor');
}

my ($FH, $log_temp_file) = tempfile();
binmode($FH, ":utf8");

my $multiplexor = Log::Any::Adapter::Multiplexor->new(
                                                        $log,
                                                        'info'  => ['Log::Any::Adapter::Stdout'],
                                                        'error' => ['Log::Any::Adapter::File', $log_temp_file]
                                                    );
#Test output in file                                                    
my $message = 'Test file log message';
$log->error($message);
like(<$FH>, "/$message/", 'Output in file');
close $FH;

#Test output to STDOUT
my ($FS, $stdout_temp_file) = tempfile();
open (STDOUT, ">>", $stdout_temp_file);
$message = 'Test STDOUT log message';
$log->info($message);
like(<$FS>, "/$message/", 'Output in stdout');
close $FS;

#Create warning log level
my ($FW, $warn_temp_file) = tempfile();
$multiplexor->set_logger('warning', 'Log::Any::Adapter::File', $warn_temp_file);
$message = 'Test warning log message in file';
$log->warning($message);
like(<$FW>, "/$message/", 'Output warning message in file');
close $FW;
