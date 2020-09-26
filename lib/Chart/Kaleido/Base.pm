package Chart::Kaleido::Base;

# ABSTRACT: Base class for Chart::Kaleido

use 5.010;
use strict;
use warnings;

# VERSION

use Moo;
use Config;
use JSON;
use Types::Standard qw(Int Str);
use File::Which qw(which);
use IPC::Run qw(timeout);
use namespace::autoclean;

use constant KALEIDO => 'kaleido';

=attr timeout

=cut

has timeout => (
    is      => 'ro',
    isa     => Int,
    default => 30,
);

has all_formats => (
    is       => 'ro',
    init_arg => 0,
    default  => sub { [] },
);

has scope_name => (
    is       => 'ro',
    init_arg => 0,
);

has scope_flags => (
    is       => 'ro',
    init_arg => 0,
    default  => sub { [] },
);

has base_command => (
    is       => 'ro',
    init_arg => 0,
    default  => sub { [KALEIDO] },
);

has _stall_timeout => (
    is      => 'lazy',
    builder => sub {
        my $self = shift;
        timeout( $self->timeout, name => 'stall timeout' );
    },
);

has _h => ( is => 'rw' );

has _ios => (
    is      => 'ro',
    default => sub {
        {
            in  => '',
            out => '',
            err => '',
        };
    },
);

sub DEMOLISH {
    my ($self) = @_;
    $self->shutdown_kaleido;
}

sub _reset {
    my ($self) = @_;
    $self->_ios->{in}  = '';
    $self->_ios->{out} = '';
    $self->_ios->{err} = '';
}

sub kaleido_command {
    my ($self) = @_;

    my @cmd = @{ $self->base_command };
    push @cmd, map {
        no strict 'refs';
        my $val = $self->$_;
        if ( defined $val ) {
            my $flag = $_;
            $flag =~ s/_/-/g;
            "--$flag=$val";
        }
        else {
            ();
        }
    } @{ $self->scope_flags };

    return \@cmd;
}

sub _check_alien {
    my ( $self, $force_check ) = @_;

    state $has_alien;

    if ( !defined $has_alien or $force_check ) {
        $has_alien = 0;
        eval { require Alien::Plotly::Kaleido; };
        if ( !$@ and Alien::Plotly::Kaleido->install_type eq 'share' ) {
            $ENV{PATH} = join(
                $Config{path_sep},
                Alien::Plotly::Kaleido->bin_dir,
                $ENV{PATH} // ''
            );
            $has_alien = 1;
        }
    }
    return $has_alien;
}

sub _kaleido_available {
    my ( $self, $force_check ) = @_;

    state $available;

    if ( !defined $available or $force_check ) {
        $available = 0;
        if ( not $self->_check_alien($force_check)
            and ( not which(KALEIDO) ) )
        {
            die "Kaleido tool (its 'kaleido' command) must be installed and "
              . "in PATH in order to export images. "
              . "Either install Alien::Plotly::Kaleido from CPAN, or install "
              . "it manually (see https://github.com/plotly/Kaleido/releases)";
        }
        $available = 1;
    }
    return $available;
}

sub _kaleido_version {
    my ( $self, $force_check ) = @_;

    state $version;

    if ( $self->_check_alien($force_check) ) {

        #$version = Alien::Plotly::Kaleido->version;
    }
    if ( $self->_kaleido_available($force_check) ) {

        #my $version = `$ --version`;
        #chomp($version);
        #$version = $version;
    }
    return $version;
}

sub ensure_kaleido {
    my ($self) = @_;

    unless ( $self->_h and $self->_h->pumpable ) {
        my $h = IPC::Run::start(
            $self->kaleido_command, \$self->_ios->{in},
            '>pty>',                \$self->_ios->{out},
            '2>',                   \$self->_ios->{err},
            $self->_stall_timeout,
        );
        $self->_h($h);

        while (1) {
            $self->_h->pump;

            my $resp = $self->_get_kaleido_out;
            if ( exists $resp->{code} and $resp->{code} == 0 ) {
                return $resp;

                #$self->_stall_timeout->reset;
            }
            else {
                die $resp->{message};
            }
        }
    }
}

sub shutdown_kaleido {
    my ($self) = @_;

    if ( $self->_h ) {
        eval { $self->_h->finish; };
        if ($@) {
            $self->_h->kill_kill;
        }
    }
    $self->_reset;
}

sub do_transform {
    my ( $self, $data ) = @_;

    $self->ensure_kaleido;
    $self->_ios->{in} .= encode_json($data) . "\n";

    my $resp = $self->_get_kaleido_out;
    return $resp;
}

sub _get_kaleido_out {
    my ($self) = @_;

    while (1) {
        $self->_h->pump;
        my $out   = $self->_ios->{out};
        my @lines = split( /\n/, $out );
        next unless @lines;

        for my $line (@lines) {
            my $data;
            eval { $data = decode_json($line); };
            next if $@;
            $self->_ios->{out} = '';    # clear out buffer
            return $data;
        }
    }
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

    my $kaleido = Chart::Plotly::Kaleido->new();
    $kaleido->save( "foo.png", decode_json($data), 'png', 1024, 768 );

=head1 DESCRIPTION


=head1 SEE ALSO

L<https://github.com/plotly/Kaleido>

L<Chart::Kaleido::Plotly>,
L<Alien::Plotly::Kaleido>


