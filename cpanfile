requires "File::ShareDir" => "1.116";
requires "File::Which" => "0";
requires "IPC::Run" => "20200505.0";
requires "JSON" => "0";
requires "MIME::Base64" => "0";
requires "Moo" => "2.0";
requires "Path::Tiny" => "0";
requires "Safe::Isa" => "0";
requires "Type::Params" => "1.004000";
requires "Types::Path::Tiny" => "0";
requires "Types::Standard" => "0";
requires "constant" => "0";
requires "namespace::autoclean" => "0";
requires "perl" => "5.010";
requires "strict" => "0";
requires "warnings" => "0";
recommends "Alien::Plotly::Kaleido" => "0";

on 'test' => sub {
  requires "Test2::V0" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Test::Pod" => "1.41";
};
