[![Build Status](https://travis-ci.org/stphnlyd/perl5-Chart-Kaleido.svg?branch=master)](https://travis-ci.org/stphnlyd/perl5-Chart-Kaleido)
[![AppVeyor Status](https://ci.appveyor.com/api/projects/status/github/stphnlyd/perl5-Chart-Kaleido?branch=master&svg=true)](https://ci.appveyor.com/project/stphnlyd/perl5-Chart-Kaleido)

# NAME

Chart::Kaleido - Base class for Chart::Kaleido

# VERSION

version 0.007\_001

# SYNOPSIS

```perl
use Chart::Kaleido::Plotly;
use JSON;

my $data = decode_json(<<'END_OF_TEXT');
{ "data": [{"y": [1,2,1]}] }
END_OF_TEXT

my $kaleido = Chart::Plotly::Kaleido->new();
$kaleido->save( file => "foo.png", plot => $data,
                widht => 1024, height => 768 );
```

# DESCRIPTION

This is base class that wraps plotly's kaleido command.
Instead of this class you would mostly want to use
its subclass like [Chart::Kaleido::Plotly](https://metacpan.org/pod/Chart%3A%3AKaleido%3A%3APlotly).

# ATTRIBUTES

## timeout

# SEE ALSO

[https://github.com/plotly/Kaleido](https://github.com/plotly/Kaleido)

[Chart::Kaleido::Plotly](https://metacpan.org/pod/Chart%3A%3AKaleido%3A%3APlotly),
[Alien::Plotly::Kaleido](https://metacpan.org/pod/Alien%3A%3APlotly%3A%3AKaleido)

# AUTHOR

Stephan Loyd <sloyd@cpan.org>

# CONTRIBUTOR

Gabor Szabo <gabor@szabgab.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
