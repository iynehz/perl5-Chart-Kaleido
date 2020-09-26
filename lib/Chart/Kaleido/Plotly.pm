package Chart::Kaleido::Plotly;

# ABSTRACT: Export static images of Plotly charts using Kaleido

use 5.010;
use strict;
use warnings;

# VERSION

use Moo;
extends 'Chart::Kaleido::Base';

use File::ShareDir;
use Types::Standard qw(Int Str);
use Types::Path::Tiny qw(File);
use Path::Tiny;
use MIME::Base64 qw(decode_base64);
use JSON;
use namespace::autoclean;

=attr timeout

=cut

my @text_formats = qw(svg json eps);

has '+all_formats' =>
  ( default => sub { [qw(png jpg jpeg webp svg pdf eps json)] } );

has '+scope_name' => ( default => 'plotly' );

has '+scope_flags' =>
  ( default => sub { [qw(plotlyjs mathjax topojson mapbox_access_token)] }, );

has '+base_command' =>
  ( default => sub { [ $_[0]->KALEIDO, qw(plotly --disable-gpu) ] }, );

=attr plotlyjs

Default value is plotly js bundled with L<Chart::Ploly>.

=attr mathjax

=attr topojson

=attr mapbox_access_token

=cut

has plotlyjs => (
    is      => 'ro',
    isa     => File,
    coerce  => 1,
    builder => sub {
        my $plotlyjs;
        eval {
            $plotlyjs = File::ShareDir::dist_file( 'Chart-Plotly',
                'plotly.js/plotly.min.js' );
        };
        return $plotlyjs;
    },
);

has [qw(mathjax topojson)] => (
    is     => 'ro',
    isa    => File,
    coerce => 1,
);

has mapbox_access_token => (
    is  => 'ro',
    isa => Str
);

sub transform {
    my ( $self, $plotly_data, $format, $width, $height, $scale ) = @_;
    $format = lc($format);
    $scale //= 1;

    unless ( grep { $_ eq $format } @{ $self->all_formats } ) {
        die "Invalid format '$format'. Supported formats: "
          . join( ' ', @{ $self->all_formats } );
    }

    my $data = {
        format => $format,
        width  => $width,
        height => $height,
        scale  => $scale,
        data   => $plotly_data,
    };
    my $resp = $self->do_transform($data);
    if ( $resp->{code} != 0 ) {
        die $resp->{message};
    }
    return $resp;
}

sub save {
    my ( $self, $dst, $plotly_data, $format, $width, $height, $scale ) = @_;

    my $resp =
      $self->transform( $plotly_data, $format, $width, $height, $scale );
    if ($resp) {
        my $img = $resp->{result};
        unless ( grep { $_ eq $format } @text_formats ) {
            $img = decode_base64($img);
        }
        path($dst)->spew_raw($img);
    }
    return;
}

1;

__END__

=pod

=head1 SYNOPSIS

    use Chart::Kaleido::Plotly;
    use JSON;

    my $data = decode_json(<<'END_OF_TEXT');
    { "data": [{"y": [1,2,1]}] }
    END_OF_TEXT

    my $kaleido = Chart::Kaleido::Plotly->new();
    $kaleido->save( "foo.png", decode_json($data), 'png', 1024, 768 );

=head1 DESCRIPTION


=head1 SEE ALSO

L<https://github.com/plotly/Kaleido>

L<Chart::Plotly>,
L<Chart::Kaleido::Base>,
L<Alien::Plotly::Kaleido>


