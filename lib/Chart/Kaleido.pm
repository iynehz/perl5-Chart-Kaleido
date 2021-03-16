package Chart::Kaleido;

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
use IPC::Run qw();
use namespace::autoclean;

use constant KALEIDO => 'kaleido';

=attr timeout

=cut

has timeout => (
    is      => 'ro',
    isa     => Int,
    default => 30,
);

has base_args => (
    is       => 'ro',
    init_arg => 0,
    default  => sub { [] },
);

has _default_chromium_args => (
    is      => 'ro',
    default => sub {
        [
            qw(
              --disable-gpu
              --allow-file-access-from-files
              --disable-breakpad
              --disable-dev-shm-usage
            )
        ];
    }
);

has disable_gpu => (
    is      => 'ro',
    default => 1,
);

has _stall_timeout => (
    is => 'lazy',
    builder =>
      sub { IPC::Run::timeout( $_[0]->timeout, name => 'stall timeout' ) },
);

has _h => ( is => 'rw' );

has _ios => (
    is      => 'ro',
    default => sub {
        return { map { $_ => '' } qw(in out err) };
    },
);

# class attributes
sub all_formats { [] }
sub scope_name  { "" }
sub scope_flags { [] }

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

sub kaleido_args {
    my ($self) = @_;

    my @args = @{ $self->base_args };
    unless ( $self->disable_gpu ) {
        @args = grep { $_ ne '--disable-gpu' } @args;
    }

    no strict 'refs';
    push @args, map {
        my $val = $self->$_;
        if ( defined $val ) {
            my $flag = $_;
            $flag =~ s/_/-/g;

            # too bad Perl does not have a core boolean type..
            if ( ref($val) =~ /^(JSON::.*::Boolean|boolean)$/ and $val ) {
                "--$flag";
            }
            else {
                "--$flag=$val";
            }
        }
        else {
            ();
        }
    } @{ $self->scope_flags };

    return \@args;
}

sub ensure_kaleido {
    my ( $self, $override_args ) = @_;
    $override_args //= $self->kaleido_args;

    unless ( $self->_h and $self->_h->pumpable ) {
        $self->_reset;
        my $h = IPC::Run::start(
            [ KALEIDO, @{ $self->kaleido_args } ],
            \$self->_ios->{in},
            \$self->_ios->{out},
            \$self->_ios->{err},
            $self->_stall_timeout,
        );
        $self->_h($h);

        $self->_stall_timeout->start;
        my $resp = $self->_get_kaleido_out;
        if ( exists $resp->{code} and $resp->{code} == 0 ) {
            return $resp->{version};
        }
        else {
            die $resp->{message};
        }
    }
}

sub shutdown_kaleido {
    my ($self) = @_;

    if ( $self->_h ) {
        eval { $self->finish; };
        if ($@) {
            $self->_h->kill_kill;
        }
    }
}

sub do_transform {
    my ( $self, $data ) = @_;

    $self->ensure_kaleido;

    my $json = JSON->new->allow_blessed(1)->convert_blessed(1);
    $self->_ios->{in} .= $json->encode($data) . "\n";
    $self->_stall_timeout->start;
    my $resp = $self->_get_kaleido_out;
    return $resp;
}

sub version {
    my ( $class, $force_check ) = @_;

    if ( $class->_check_alien($force_check) ) {
        return Alien::Plotly::Kaleido->version;
    }
    else {
        state $version;
        if ( not $version or $force_check ) {
            $version = $class->_detect_kaleido_version;
        }
        return $version;
    }
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
            $self->_stall_timeout->reset;
            $self->_ios->{out} = '';    # clear out buffer
            return $data;
        }
    }
}

sub _check_alien {
    my ( $class, $force_check ) = @_;

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
    my ( $class, $force_check ) = @_;

    state $available;
    if ( !defined $available or $force_check ) {
        $available = 0;
        if ( not $class->_check_alien($force_check)
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

sub _detect_kaleido_version {
    my ($class) = @_;

    my $kaleido = which('kaleido');
    if ($kaleido) {
        my $kaleido = $class->new;
        my $args    = [ 'plotly', '--disable-gpu' ];
        my $version = $kaleido->ensure_kaleido($args);
        $kaleido->shutdown_kaleido;
        return $version;
    }

    die "Failed to detect kaleido version";
}

__PACKAGE__->_kaleido_available;

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
    $kaleido->save( file => "foo.png", plot => $data,
                    widht => 1024, height => 768 );

=head1 DESCRIPTION

This is base class that wraps plotly's kaleido command.
Instead of this class you would mostly want to use
its subclass like L<Chart::Kaleido::Plotly>.

=head1 SEE ALSO

L<https://github.com/plotly/Kaleido>

L<Chart::Kaleido::Plotly>,
L<Alien::Plotly::Kaleido>

