#!/usr/bin/env perl
######################### Sample invocation
# plackup pgspray_hist.psgi 
#
# config should exist at  etc/default/pgspray
#
# NOTE: bucket boundaries are forever fixed at  5, 6, 7, 8, 10, 15, 25, 50, and 90  msec
#
# You could also picture this histogram data as a heatmap by using the query: sum(increase(http_request_duration_seconds_bucket[10m])) by (le), making sure to set the format as "heatmap," the legend format as {{ le }}, and setting the visualization in the panel settings to "heatmap."




use strict;
use v5.10;
use warnings;
use DBI;
use Time::HiRes qw( time usleep );
use feature qw( switch );
use Getopt::Std ;
no if $] >= 5.018, warnings => qw( experimental::smartmatch );
use Data::Dumper;
use Net::Prometheus;
use Config::INI::Reader;
use File::Slurp; 
#use HTTP::Date qw(time2iso time2str) ;


use constant RC_FILES  => qw( ini pgspray.ini  /etc/default/pgspray /etc/default/pgspray.ini  ); 
use constant DEFAULTS => {  
           host_ip            => $ENV{PGHOST}     || 'localhost', 
           hostname           => 'localhost', 
           port               => $ENV{PGPORT}     ||  5432,
           sslmode            => $ENV{PGSSLMODE}  || 'prefer',
           user               => $ENV{PGUSER}     ||'prometheus',
           database           => $ENV{PGDATABASE} || 'postgres',
           password           => $ENV{PGPASSWORD} ||  undef,
           chmod              =>  0640 ,
           timeout            =>  4,
	   secret_file        => '/etc/prometheus/exporters/secret',
           output_interval    =>  60,
           outdir             =>  '/var/lib/prometheus/node-exporter/node_dat',
           out_mode           =>  'stdout',        #  push, file, stdout
           one_shot           =>  undef,
           samples_per_minute =>  20 ,
           sql                =>  "SELECT 'response_tme'" ,
          outfile             => '/var/lib/prometheus/node-exporter/node_dat/pgspray.prom' ,
          once_shot           =>  undef,
          #sql                =>  "SELECT current_setting('server_version')",
     }; 

#############  Read Config
sub find_config { 
    -r $_ && return $_  for RC_FILES  
}
sub read_config {
        my ($defaults, $file) = @_;
        my $in = Config::INI::Reader->read_file( $file );
        my $result;
        for my $k (keys %$in) {
            next  if $k =~ /^common$/i ;
            next  if $k =~ /^#/        ;
            my $tmp = DEFAULTS()       ;
            my $entry;
            for (keys %{$in->{common}}) { 
                $entry     = $in->{common}{$_}            ;
                $entry     =~ s/\s+[#].*$//               ;
                $entry     =~ s/^\s*[#]//                 ;
                $tmp->{$_} = $entry    unless /^\s*[#]/   ;
            }

            for (keys %{$in->{$k}})   {
                $entry     = $in->{$k}{$_}                ;
                $entry     =~ s/\s*[#].*$//               ;
                $entry     =~ s/^\s*[#]//                 ;
                $tmp->{$_} = $entry    unless /^\s*[#]/   ;
            }
            $result->{$k} = { %$tmp };
        }
        return $result;
}
sub calc_passwd {
       my $o = shift;
        $o->{password} and return $o->{password} ;

        if ( $o->{secret_file}) {
                my $passwd = read_file($o->{secret_file} ) || die;
                warn "password from file \"".  $o->{secret_file}. "\"\n";
                chomp $passwd ;
                return $passwd ;
        }
        undef;
}
sub calc_percentile {
        my ($per, $vals) = @_;
        my $pindex = ($per < 100) ? int(1+(($per/100)*scalar @$vals)) : scalar @$vals;
        $vals->[$pindex-1];
}
sub main_work ;
#my $pm   = new Parallel::ForkManager( 3 );
############################################## Process ARGV
my %arg ;
getopts('f:1', \%arg);


my $ini   =  $arg{f}  || find_config()          ;
my $once  =  $arg{1}                            ;
my $conf  =  read_config( DEFAULTS, $ini)       ;

#############################################  Read Config
my $one = 'yes';

my @clusters  = keys %$conf;
my $metric_name = 'pgspray';

my $prom ;
for (1..@clusters) {
                 $prom->{$clusters[-1+$_]} = Net::Prometheus->new( disable_process_collector => ($_<2)?1:0,
        	         	      	                           disable_perl_collector    => ($_<2)?1:0,    )
}

my $hist;
$hist->{$_} = $prom->{$_}->new_histogram ( name    => $metric_name,
                                           help    =>  'Time responce of posgresql request (in msec).', 
                                           labels  => [qw/hostname host_ip port  cluster /] ,
                                           buckets =>  [qw/ 4 6 7 8 10 25 50 90 /])   for (@clusters);
my $app = sub {
     #############################################  MAIN
        $conf->{$_}{password} =  calc_passwd $conf->{$_}    for (@clusters);
     my ($msec_BETWEEN_SAMPLES, $result, $dbh, $labels, $DSN);
     my $att = { AutoCommit => 0, ReadOnly => 1};
     my $url =  'http://qft:9091'. '/metrics/job/pgspray';
        for (@clusters) {
                $msec_BETWEEN_SAMPLES->{$_}   =  1_000 * 60 / $conf->{$_}{samples_per_minute} ;
                $labels->{$_} = { hostname=> $conf->{$_}{hostname}, host_ip=>$conf->{$_}{host_ip}, 
                                port=>$conf->{$_}{port}, cluster=>$conf->{$_}{cluster} }  ;
                $DSN->{$_}    = "dbi:Pg:host=$conf->{$_}{host_ip};port=$conf->{$_}{port};dbname=$conf->{$_}{database};sslmode=$conf->{$_}{sslmode};application_name=$conf->{$_}{appname}"   for (@clusters);
        }
	######################################################
		eval { 
			local $SIG{ALRM} = sub { die "timeout" }; 
                        alarm $conf->{$clusters[0]}{output_interval}; 
			my ($start_time, $end_time,  $elapsed);
			while(1) {
                                 for (@clusters) {
                                         $start_time->{$_} = time()    for (@clusters);
                                         $dbh->{$_} = DBI->connect($DSN->{$_}, $conf->{$_}{user},
                                                                   $conf->{$_}{password}, $att) or die "@_\n" ;
                                         $dbh->{$_}->do( $conf->{$_}{sql} );

                                         $end_time->{$_} = time();
                                         $elapsed->{$_}  = ($end_time->{$_} - $start_time->{$_})*1000;   # mill sec
                                         $dbh->{$_}->rollback;
                                         $hist->{$_}->observe( $labels->{$_}, $elapsed->{$_} );
				         usleep( $msec_BETWEEN_SAMPLES->{$_} * 1_000 ); 
                               } # for
		      } # while
		};  # eval
		alarm 0; # cancel the alarm 
                my $msg;
                for (@clusters) {
                                $dbh->{$_}->rollback;
                                $msg .= $prom->{$_}->render ;
                }
                return [
                        '200',
                        [ 'Content-Type' => 'text/plain' ],
                        [ $msg  ],
                 ];
}
