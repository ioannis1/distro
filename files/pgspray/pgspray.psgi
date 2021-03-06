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
           out_dir            =>  '/var/lib/prometheus/node-exporter/node_dat',
           out_mode           =>  'stdout',        #  push, file, stdout
           samples_per_minute =>  20 ,
           sql                =>  "SELECT 'response_tme'" ,
          outfile             => '/var/lib/prometheus/node-exporter/node_dat/pgspray.prom' ,
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
sub calc_truth_false {
       my $val = shift;
       return undef unless $val;
       return undef if $val =~ '^\s*$';
       return undef if $val =~ '^(undef|none|na)$';
       return undef if $val =~ /^(no|false|0)$/i;
       return $val;
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
my $one = 'yes';

########## Global
my $dbh;
#############################################  Read Config
sub form_dsn {
        my $o = shift;
        "dbi:Pg:host=$o->{host_ip};port=$o->{port};dbname=$o->{database};sslmode=$o->{sslmode};application_name=$o->{appname}" 
}
sub calc_between_samples {
        my $o = shift;
	1_000 * 60 / $o->{samples_per_minute} ;
}
sub form_labels {
        my $o = shift;
        { hostname=> $o->{hostname}, host_ip=>$o->{host_ip}, port=>$o->{port}, cluster=>$o->{cluster} }  ;
}
sub take_observation {
        my ($o, $dsn, $att) = @_ ;
        my ($start_time, $end_time);
        $start_time = time();
        $dbh        = DBI->connect($dsn, $o->{user},$o->{password}, $att) or die "@_\n" ;
        #$dbh->do("SELECT 3");
        $dbh->do( $o->{sql} );
        $end_time   = time();
        $dbh->rollback;
       ($end_time - $start_time)*1000;   # in mill seconds
}

my @clusters          = keys %$conf;
my $metric_name       = 'pgspray';
my $metric_name_summa =  $metric_name . '_response';

my ($prom, $prom_summa) ;
for (1..@clusters) {
                 $prom->{$clusters[-1+$_]} = Net::Prometheus->new(       disable_process_collector => ($_<2)?1:0,
        	         	      	                                 disable_perl_collector    =>1);# ($_<2)?1:0);
                 $prom_summa->{$clusters[-1+$_]} = Net::Prometheus->new( disable_process_collector => 1,
        	         	      	                                 disable_perl_collector    => 1);
}

my $hist;
$hist->{$_} = $prom->{$_}->new_histogram ( name    => $metric_name,
                                           help    =>  'Time responce of posgresql request (in msec).', 
                                           labels  => [qw/hostname host_ip port  cluster /] ,
                                           buckets =>  [qw/ 4 6 7 8 10 25 50 90 /])   for (@clusters);
my $summa;
$summa->{$_} = $prom_summa->{$_}->new_summary ( name    => $metric_name_summa,
                                                help    =>  'Time responce of posgresql request (in msec).', 
                                                labels  => [qw/hostname host_ip port  cluster /] )  for (@clusters);
sub output_qsummary {
        my ($metric,$o, $result) = @_ ;
        my $msg ;
        my $res =  [ sort {$a<=>$b } (@{$result}) ];
        for my $quantile (qw/ 0.5 0.8  0.9  0.95/  ) {
                $msg .=sprintf qq(%s{hostname="%s",host_ip="%s",pg_port="%d",cluster="%s",quantile="%s"} %4f\n), 
                $metric, $o->{hostname},$o->{host_ip}, $o->{port} ,
                $o->{cluster}, $quantile,  calc_percentile( $quantile*100 , $res);
        } # for quantile
	$msg;
}
my $app = sub {
     #############################################  MAIN
        $conf->{$_}{password}   =  calc_truth_false $conf->{$_}{password}   for(@clusters)  ;
        $conf->{$_}{password}   =  calc_passwd $conf->{$_}                  for (@clusters);
     my ($msec_BETWEEN_SAMPLES, $result, $dbh, $labels, $DSN);
     my $att = { AutoCommit => 0, ReadOnly => 1};
     my $url =  'http://qft:9091'. '/metrics/job/pgspray';
        for (@clusters) {
                $msec_BETWEEN_SAMPLES->{$_}   =  calc_between_samples($conf->{$_});
                $labels->{$_}                 =  form_labels($conf->{$_}) ;
                $DSN->{$_}                    =  form_dsn($conf->{$_})    ;
        }
	######################################################
		eval { 
			local $SIG{ALRM} = sub { die "timeout" }; 
                        alarm $conf->{$clusters[0]}{output_interval}; 
			my ($start_time, $end_time,  $elapsed);
			while(1) {
                                 for (@clusters) {
                                         $elapsed->{$_}  = take_observation($conf->{$_}, $DSN->{$_}, $att);  
                                         $hist->{$_}->observe( $labels->{$_}, $elapsed->{$_} );
					 push @{$result->{$_}}, $elapsed->{$_};
					 $summa->{$_}->observe( $labels->{$_}, $elapsed->{$_} );
				         usleep( $msec_BETWEEN_SAMPLES->{$_} * 1_000 ); 
                               } # for
		      } # while
		};  # eval
		alarm 0; # cancel the alarm 
#############  SUMMARY  OUTPUT
                my $msg_summa;
		for (@clusters) {
			        #$dbh->{$_}->rollback;
				$msg_summa->{$_} =  $prom_summa->{$_}->render  
			                    .  output_qsummary($metric_name_summa, $conf->{$_}, $result->{$_});
                } # for clusters    
                my $msg = join("\n",values %$msg_summa)    ; 
#############  HISTOOGRAM  OUTPUT
                for (@clusters) {
			#$dbh->{$_}->rollback;
				$msg .= $prom->{$_}->render ;
                }
##################################  OUPUT
                return [
                        '200',
                        [ 'Content-Type' => 'text/plain' ],
			[ $msg ],
                 ];
}
