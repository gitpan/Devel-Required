package Devel::Required;

# set version information
$VERSION= '0.11';

# make sure we do everything by the book from now on
use strict;
use warnings;

# initializations
my @TEXT;  # list with text-file conversion
my @POD;   # list with pod-file conversion

# replace WriteMakefile with our own copy
BEGIN {
    no warnings 'redefine';
    no strict 'refs';
    my $subname= caller() . '::WriteMakefile';
    my $old= \&{$subname};
    *$subname= sub {

        # perform the old sub with parameters
        @_= @_; # quick fix for brokennes in 5.9.5, as suggested by rgs
        $old->( @_ );

        # initializations
        my $pod;       # pod filename to change
        my $modules;   # hash reference to the module info
        my $required;  # required text to replace
        my $version;   # version text to replace

        # each key and value pair passed to original WriteMakefile
        while (@_) {
            my ( $key, $value )= ( shift, shift );

            # main module file
            if ( $key eq 'VERSION_FROM' ) {
                $pod= $value;
            }

            # required modules hash ref
            elsif ($key eq 'PREREQ_PM') {
                $modules= $value;
            }

=for Explanation:
     Anything we don't handle is simply ignored.

=cut

        }

        # use E::M's logic to obtain version information
        ($version)= _slurp('Makefile') =~ m#\nVERSION = (\d+\.\d+)#s;

        # text to insert
        $required= join $/,
          map {" $_ (".($modules->{$_} || 'any').")"}
          sort {lc $a cmp lc $b}
           keys %{$modules}
             if $modules;
        $required ||= " (none)";

        # convert all text files that matter
        foreach ( grep { -s } @TEXT ? @TEXT : 'README' ) {
            _convert( $_, "Version:$/", " $version", "$/$/" )
              if $version;
            _convert( $_, "Required Modules:$/", $required, "$/$/" );
        }

        # convert all pod files that matter
        foreach ( grep { -s } @POD ? @POD : ($pod ? ($pod) : () ) ) {
            _convert(
              $_,
              "=head1 VERSION$/",
              "$/This documentation describes version $version.$/", "$/="
            ) if $version;
            _convert( $_, "=head1 REQUIRED MODULES$/", "$/$required$/", "$/=" );
        }
    };
}    #BEGIN

# satisfy -require-
1;

#-------------------------------------------------------------------------------
#
# Standard Perl features
#
#-------------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2..N key/value pairs

sub import {

    # lose the class
    shift;

    # for all key value pairs
    while (@_) {
        my ( $type, $file )= ( shift, shift );

        # set up text file processing
        if ( $type eq 'text' ) {
            push @TEXT, ref $file ? @{$file} : ($file);
        }

        # set up pod file processing
        elsif ( $type eq 'pod' ) {
            push @POD,ref $file ? @{$file} : ($file);
        }

        # huh?
        else {
            die qq{Don't know how to handle "$type"\n};
        }
    }
}    #import

#-------------------------------------------------------------------------------
#
# Internal subroutines
#
#-------------------------------------------------------------------------------
# _convert
#
# Perform the indicated conversion on the specified file
#
#  IN: 1 filename
#      2 string before to match
#      3 string to insert between before and after
#      4 string to match with after

sub _convert {
    my ( $filename, $before, $text, $after )= @_;
    local $_;

=for Explanation:
     We want to make sure that this also runs on pre 5.6 perl's, so we're
     using old style open()

=cut

    # there is something to process
    if ( my $contents= $_= _slurp($filename) ) {

        # found and replaced text
        if ( s#$before(?:.*?)$after#$before$text$after#s ) {

            # same as before (no action)
            if ($_ eq $contents) {
            }

            # successfully saved file with changes
            elsif ( open( OUT, ">$filename" ) ) {
                print OUT $_;
                close OUT
                 or die qq{Problem flushing "$filename": $!\n};
                die qq{Did not properly install "$filename"\n}
                 unless -s $filename == length;
            }

            # could not save file
            else {
                warn qq{Could not open "$filename" for writing: $!\n};
            }
        }

        # couldn't replace
        else {
            $before =~ s#\s+$##s;
            warn qq{Could not find text marker "$before" in "$filename"\n};
        }
    }
}    #_convert

#-------------------------------------------------------------------------------
# _slurp
#
# Return contents of given filename, a poor man's perl6 slurp().  Warns if
# it could not open the specified file
#
#  IN: 1 filename
# OUT: 1 file contents

sub _slurp {
    my ($filename)= @_;
    my $contents;

    # there is something to process
    if ( open( IN, $filename ) ) {
        $contents= do { local $/; <IN> };
        close IN;
    }

    # couldn't read file
    else {
        warn qq{Could not open "$filename" for reading: $!\n};
    }

    return $contents;
}    #_slurp

#-------------------------------------------------------------------------------

__END__

=head1 NAME

Devel::Required - automatic update of required modules documentation

=head1 VERSION

This documentation describes version 0.11.

=head1 SYNOPSIS

 use ExtUtils::MakeMaker; # check README and lib/Your/Module.pm
 eval "use Devel::Required";
 WriteMakefile (
  NAME         => "Your::Module",
  VERSION_FROM => "lib/Your/Module.pm",
  PREREQ_PM    => { 'Foo' => '1.0', 'Bar::Baz' => '0.05' }
 );

 use ExtUtils::MakeMaker; # specify which files should be checked
 eval "use Devel::Required text => 'INSTALL', pod => [qw(lib/Your/Module.pod)]"
 WriteMakefile (
  NAME         => "Your::Module",
  VERSION_FROM => "lib/Your/Module.pm",
  PREREQ_PM    => { 'Foo' => '1.0', 'Bar::Baz' => '0.05' }
 );

=head1 DESCRIPTION

The Devel::Required module only serves a purpose in the development environment
of an author of a CPAN module (or more precisely: a user of the
L<ExtUtils::MakeMaker> module).  It makes sure that any changes to the
required modules specified in the Makefile.PL are automatically reflected
in the appropriate text file and in the appropriate source files (either
explicitely or implicitely specified).

It takes the information given with the PREREQ_PM parameter and by default
writes this to the README file, as well as to the POD of the file specified
with the VERSION_FROM parameter.  Both these defaults can be overridden with
the "text" and "pod" parameters in the C<use Devel::Required> specification.

This module should B<only> be installed on the system of the developer.

=head1 FILES CHANGED

By default the following types of files will be changed:

=over 2

=item text file

A text file should at least have one of these marker texts:

 Version:                     <- must start at beginning of line
                              <- empty line
                              <- another empty line

 Required Modules:            <- must start at beginning of line
                              <- empty line
                              <- another empty line

After Makefile.PL is executed (using the example of the L<SYNOPSIS>), the
above will be changed to:

 Version:                                    <- must start at beginning of line
  This documentation describes version #.##. <- added 
                                             <- empty line

 Required Modules:                           <- must start at beginning of line
  Foo (1.0)                                  <- added
  Bar::Baz (0.05)                            <- added
                                             <- empty line

No changes will be made if none of the marker texts are not found.

If no "text" file specification is specified, then the file "README" in the
current directory will be assumed.

=item pod file

The pod file(s) that are (implicitely) specified, will be searched for
any marker texts that consist of the lines:

 =head1 VERSION               <- must start at beginning of line
                              <- empty line
 =(anything)                  <- any other pod directive

 =head1 REQUIRED MODULES      <- must start at beginning of line
                              <- empty line
 =(anything)                  <- any other pod directive

After Makefile.PL is executed (using the example of the L<SYNOPSIS>, the
above will be changed to:

 =head1 VERSION                              <- must start at beginning of line
                                             <- empty line
 This documentation describes version #.##.  <- added
                                             <- added
 =(anything)                                 <- any other pod directive

 =head1 REQUIRED MODULES                     <- must start at beginning of line
                                             <- empty line
  Foo (1.0)                                  <- added
  Bar::Baz (0.05)                            <- added
                                             <- added
 =(anything)                                 <- any other pod directive

No changes will be made if none of the marker texts are not found.

If no "pod" file specification is specified, then the file specified with the
"VERSION_FROM" parameter of the call to C<WriteMakefile> will be assumed.

=back

=head1 SPECIFYING YOUR OWN FILES

It is possible to specify which text and which pod files should be searched
for the text markers and possibly updated.  The C<import> routine of
Devel::Required takes a list of parameters, each pair of which is considered
to be a key-value pair.  The following keys are recognized:

=over 2

=item text

The value of this parameter is either the name of the text file to check, or
a reference to a list with the names of one or more text files.

=item pod

The value of this parameter is either the name of a file containing pod to
check, or a reference to a list withe the names of one or more files containing
pod.

=back

=head1 REQUIRED MODULES

 (none)

=head1 THEORY OF OPERATION

Loading this module steals the "WriteMakefile" subroutine of the calling
package and inserts its own logic for updating the necessary text-files.
The version information is read from the generated "Makefile".

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 ACKNOWLEDGEMENTS

Castaway on Perl Monks for "complaining" about not mentioning prerequisite
modules in the README or in the POD.

Dan Browning for suggestion being able to specify which text and pod files
should be changed.

=head1 COPYRIGHT

Copyright (c) 2003, 2004, 2006, 2007, 2009, 2012 Elizabeth Mattijsen
<liz@dijkmat.nl>.  All rights reserved.  This program is free software; you
can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<ExtUtils::MakeMaker>.

=cut
