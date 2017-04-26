package Log::Any::Adapter::Multiplexor;

use 5.008001;

use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use Carp 'croak';
use Log::Any::Adapter;
#Default adapter
Log::Any::Adapter->set('Stdout');
use Data::Printer;
 
our $VERSION    = '0.01';

my %LOG_LEVELS = (
                    '0'     => 'EMERGENCY',
                    '1'     => 'ALERT',
                    '2'     => 'CRITICAL',
                    '3'     => 'ERROR',
                    '4'     => 'WARNING',
                    '5'     => 'NOTICE',
                    '6'     => 'INFO',
                    '7'     => 'DEBUG',
                    '8'     => 'TRACE',
                );

sub new {
    my $class = shift;
    my $log = shift;
    my %opt = @_;
    my $self = {};
    $self->{log} = $log;
    bless $self, $class;


    for my $key (keys %opt) {
        my $adapter = shift @{$opt{$key}};
        my @param = @{$opt{$key}};
        $self->set_logger($key, $adapter, @param);

    }

    $log->{filter} = sub {
                                no strict 'refs';
                                my $log_level_name = $LOG_LEVELS{$_[1]} || 'trace';
                                $log_level_name = lc($log_level_name);
                                $self->{adapters}->{$log_level_name}->$log_level_name($_[2]);
                                return '';
    };

    return $self;
}


sub set_logger {
    no strict 'refs';
    my ($self, $log_level, $package, @param) = @_;
    my $log = $self->{log};
    $self->{adapters}->{$log_level} = $log->clone();
    eval "require $package";
    if ($@) {
        croak $@;
    }
    $self->{adapters}->{$log_level} = $package->new(@param);

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::Multiplexor - Run any Log::Any:Adapter together

=head1 VERSION

 version 0.01

=head1 SYNOPSIS
    #log warn message to a file, but info message to Stdout
    use Log::Any '$log';
    use Log::Any::Adapter;
    use Log::Any::Adapter::Multiplexor;

    #Create Log::Any::Adapter::Multiplexor object
    my $multiplexor = Log::Any::Adapter::Multiplexor->new(
                                                              $log,
                                                              'error' => ['Log::Any::Adapter::File', 'log.txt'],
                                                              'info'  => ['Log::Any::Adapter::Stdout'],
                                                            );
    #Log message to file log.txt
    $log->info("Test info");

    #Log message to Stdout
    $log->error("Test error");

    #You can override the behavior of log level
    #Example: Send warning log message to file warn_log.txt
    $multiplexor->set_logger('warning', 'Log::Any::Adapter::File', 'warn_log.txt');
    $log->warning('Warning message');

=head1 DESCRIPTION
    Log::Any::Adapter::Multiplexor connects any Log::Any::Adapter to use together

=head1 Functions
    Specification function

=head2 new
    my $multiplexor = Log::Any::Adapter::Multiplexor->new($log, %param);

    $log - $Log::Any::log object
    %param
        key     => Log level name
        value   => Arrayref ['Adapter name', @params]

=head2 set_logger
    Set or override exists logger for Log::Any::Adapter::Multiplexor object

    $multiplexor->set_logger($log_level, $adapter, @param);
    $log_level  => Log levels (e.g. warning, info, error)
    $adapter    => Log::Any::Adapter for this log level (etc 'Log::Any::Adapter::File)
    @param      => Adapter params (e.g. filename)

=head1 AUTHORS

    Pavel Andryushin <vrag867@gmail.com>

=head1 COPYRIGHT AND LICENSE

    This software is copyright (c) 2017 by Pavel Andryushin.

    This is free software; you can redistribute it and/or modify it under
    the same terms as the Perl 5 programming language system itself.

=cut

