BEGIN {				# Magic Perl CORE pragma
    chdir 't' if -d 't';
    unshift @INC,'../lib';
}

use Test::More tests => 3 + (3*3) + 10 + (2*7) + 1;
use strict;
use warnings;

use_ok( 'ExtUtils::MakeMaker' );
use_ok( 'Devel::Required' );
can_ok( 'Devel::Required',qw(import) );


foreach (qw(Foo Bar Baz)) {
    ok( open( OUT,">$_.pm" ), "Failed to open $_.pm: $!" );
    print OUT <<EOD;
package $_;
\$VERSION = '1.01';

=head1 SYNOPSIS

This is just an example module.

=head1 REQUIRED MODULES

=head1 COPYRIGHT


More text.
EOD
    ok( close OUT, "Failed to close $_.pm: $!" );
    ok( -e "$_.pm","Check if $_.pm exists" );
}


ok( open( OUT,">README" ), "Failed to open README for writing: $!" );
print OUT <<EOD;
Sample README file

Required Modules:


More text.
EOD
ok( close OUT, "Failed to close README for writing: $!" );
ok( -e 'README',"Check if README exists" );

WriteMakefile (
 NAME           => "Foo",
 VERSION_FROM   => 'Foo.pm',
 PREREQ_PM      => { 'Bar' => '1.0', 'Baz' => 0},
);
ok( -e 'Makefile', "Check if Makefile exists" );


ok( open( IN,"README" ), "Failed to open README for reading: $!" );
is( do {local $/; <IN>},<<EOD, "Check if README conversion successful" );
Sample README file

Required Modules:
 Bar (1.0)
 Baz (any)

More text.
EOD
ok( close IN, "Failed to close README: $!" );


ok( open( IN,"Foo.pm" ), "Failed to open Foo.pm for reading: $!" );
is( do {local $/; <IN>},<<EOD, "Check if Foo.pm conversion successful" );
package Foo;
\$VERSION = '1.01';

=head1 SYNOPSIS

This is just an example module.

=head1 REQUIRED MODULES

 Bar (1.0)
 Baz (any)

=head1 COPYRIGHT


More text.
EOD
ok( close IN, "Failed to close Foo.pm: $!" );


foreach (
 { NAME => "Foo", VERSION_FROM => 'Foo.pm', PREREQ_PM => {} },
 { NAME => "Foo", VERSION_FROM => 'Foo.pm' }
) {
    WriteMakefile ( %{$_} );
    ok( -e 'Makefile', "Check if Makefile exists" );


    ok( open( IN,"README" ), "Failed to open README for reading: $!" );
    is( do {local $/; <IN>},<<EOD, "Check if README conversion successful" );
Sample README file

Required Modules:
 (none)

More text.
EOD
    ok( close IN, "Failed to close README: $!" );


    ok( open( IN,"Foo.pm" ), "Failed to open Foo.pm for reading: $!" );
    is( do {local $/; <IN>},<<EOD, "Check if Foo.pm conversion successful" );
package Foo;
\$VERSION = '1.01';

=head1 SYNOPSIS

This is just an example module.

=head1 REQUIRED MODULES

 (none)

=head1 COPYRIGHT


More text.
EOD
    ok( close IN, "Failed to close Foo.pm: $!" );
}

my @file = (qw(README Makefile),map {"$_.pm"} qw(Foo Bar Baz));
is( unlink( @file ),scalar @file, "Check if all files removed" );
1 while unlink @file; # multiversioned filesystems
