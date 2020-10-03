#!perl

use JSON;
use Path::Tiny;
use File::Which qw(which);

use Test2::V0;
use Chart::Kaleido::Plotly;

my $kaleido = Chart::Kaleido::Plotly->new();

diag "kaleido args: " . join( ' ', @{ $kaleido->kaleido_args } );

#if ($@) {
#    skip_all("kaleido seems not available: $@");
#}

ok("create kaleido object");

my $data = decode_json(<<'END_OF_TEXT');
{ "data": [{"y": [1,2,1]}] }
END_OF_TEXT

my $tempdir = Path::Tiny->tempdir;
$kaleido->save(
    file   => "$tempdir/foo.png",
    plotly => $data,
    width  => 1024,
    height => 768
);

ok( ( -f "$tempdir/foo.png" ), "generate image" );

done_testing;
