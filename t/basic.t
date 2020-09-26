#!perl

use JSON;
use File::Temp qw(tempdir);
use File::Which qw(which);

use Test2::V0;
use Chart::Kaleido::Plotly;


my $kaleido = Chart::Kaleido::Plotly->new( timeout => 20 );

diag join(' ', @{$kaleido->kaleido_command});
#if ($@) {
#    skip_all("kaleido seems not available: $@");
#}

ok("create kaleido object");

my $data = decode_json(<<'END_OF_TEXT');
{ "data": [{"y": [1,2,1]}] }
END_OF_TEXT

my $tempdir = tempdir( CLEANUP => 1 );
$kaleido->save( "$tempdir/foo.png", $data, 'png', 1024, 768 );

ok( ( -f "$tempdir/foo.png" ), "generate image" );

done_testing;
