package Devel::Required;

# Make sure we have version info for this module
# Make sure we do everything by the book from now on

$VERSION = '0.06';
use strict;

# Initialize the list with text-file conversion
# Initialize the list with pod-file conversion

my @TEXT;
my @POD;

# While we're compiling
#  Make sure we can redefine without problems
#  Obtain the subroutine name
#  Save the current subroutine
#  Replace it by a subroutine which
#   Executes the original subroutine with the original parameters first

BEGIN {
    no warnings 'redefine'; no strict 'refs';
    my $subname = caller().'::WriteMakefile';
    my $old = \&{$subname};
    *$subname = sub {
        $old->( @_ );

#   Initialize pod filename to change
#   Initialize the hash reference to the module info
#   Initialize the text to replace

        my $pod;
        my $modules;
        my $text;

#   While there are parameters to be processed
#    Get the next key/value pair
#    If it refers to the main module file
#     Set that
#    Elseif it is the required modules hash ref
#     Set that

        while (@_) {
            my ($key,$value) = (shift,shift);
            if ($key eq 'VERSION_FROM') {
                $pod = $value;
            } elsif ($key eq 'PREREQ_PM') {
                $modules = $value;
            }
        }

#    Initialize the text to insert
#    Make sure there is something there

        $text = join( $/,
         map {" $_ (".($modules->{$_} || 'any').")"}
          sort {lc $a cmp lc $b} keys %{$modules} )
           if $modules;
        $text ||= " (none)";

#    For all of the text-files to convert
#     Convert the text-file if there is one
#    For all of the text-files to convert
#     Convert the pod-file if there is one

        foreach (@TEXT ? @TEXT : 'README') {
            _convert( $_,"Required Modules:$/",$text,"$/$/" ) if -e;
        }
        foreach (@POD ? @POD : ($pod ? ($pod) : ())) {
            _convert( $_,"=head1 REQUIRED MODULES$/","$/$text$/","$/=" ) if -e;
        }
    };
} #BEGIN

#---------------------------------------------------------------------------

# Standard Perl features

#---------------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2..N key/value pairs

sub import {

# Lose the class
# While there are parameters to be handled
#  Obtain the type and value to set
#  If it is a text-file to set
#   Set that
#  Elseif it is a text-file to set
#   Set that
#  Else (what?)
#   Croak

    shift;
    while (@_) {
        my ($type,$file) = (shift,shift);
        if ($type eq 'text') {
            push @TEXT,ref( $file ) ? @{$file} : ($file);
        } elsif ($type eq 'pod') {
            push @POD,ref( $file ) ? @{$file} : ($file);
        } else {
            die qq{Don't know how to handle "$type"\n};
        }
    }
} #import

#---------------------------------------------------------------------------

# Internal subroutines

#---------------------------------------------------------------------------
# _convert
#
# Perform the indicated conversion on the specified file
#
#  IN: 1 filename
#      2 string before to match
#      3 string to insert between before and after
#      4 string to match with after

sub _convert {

# Obtain the parameters
# Make sure we have a local copy of $_

    my ($filename,$before,$text,$after) = @_;
    local $_;

# If we can read the file
#  Obtain the entire contents of the file
#  Close the input handle

    if (open( IN,$filename )) {
        my $contents = $_ = do {local $/; <IN>};
        close IN;

#  If we found and replaced the text and it's different now
#   If there was no change (no action)
#   Elseif we can open the file for writing
#    Write the new contents in there
#    Close the output handle, die if failed
#    Check size is ok, die if failed

        if (s#$before(?:.*?)$after#$before$text$after#s) {
            if ($_ eq $contents) {
            } elsif (open( OUT,">$filename" )) {
                print OUT $_;
                close OUT
                 or die qq{Problem flushing "$filename": $!\n};
                die qq{Did not properly install "$filename"\n}
                 unless -s $filename == length;

#   Else (could not open file for writing)
#    Just warn
#  Else (didn't find text marker)
#   Just warn
# Else (could not open file for reading)
#  Just warn

            } else {
                warn qq{Could not open "$filename" for writing: $!\n};
            }
        } else {
            warn qq{Could not find text marker in "$filename"\n};
        }
    } else {
        warn qq{Could not open "$filename" for reading: $!\n};
    }
} #_convert

# Satisfy -require-

1;

#---------------------------------------------------------------------------

__END__

=head1 NAME

Devel::Required - Automatic update of required modules documentation

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

A text file should at least have this marker text:

 Required Modules:            <- must start at beginning of line
                              <- empty line
                              <- another empty line

After Makefile.PL is executed (using the example of the L<SYNOPSIS>), the
above will be changed to:

 Required Modules:            <- must start at beginning of line
  Foo (1.0)                   <- added
  Bar::Baz (0.05)             <- added
                              <- empty line

No changes will be made if the marker text is not found.

If no "text" file specification is specified, then the file "README" in the
current directory will be assumed.

=item pod file

The pod file(s) that are (implicitely) specified, will be searched for
a marker text that consists of the lines:

 =head1 REQUIRED MODULES      <- must start at beginning of line
                              <- empty line
 =(anything)                  <- any other pod directive

After Makefile.PL is executed (using the example of the L<SYNOPSIS>, the
above will be changed to:

 =head1 REQUIRED MODULES      <- must start at beginning of line
                              <- empty line
  Foo (1.0)                   <- added
  Bar::Baz (0.05)             <- added
                              <- empty line
 =(anything)                  <- any other pod directive

No changes will be made if the marker text is not found.

If no "pod" file specification is specified, then the file specified with the
"VERSION_FROM" parameter of the call to C<WriteMakefile> will be assumed.

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


=head1 REQUIRED MODULES

 (none)

=head1 TODO

Support for Module::Build should be added.  Patches are welcome.  Probably
will do this myself at some point in the future when I migrate all of my
modules from L<ExtUtils::MakeMaker> to L<Module::Build>.

=head1 THEORY OF OPERATION

Loading this module steals the "WriteMakefile" subroutine of the calling
package and inserts its own logic for updating the necessary text-files.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 ACKNOWLEDGEMENTS

Castaway on Perl Monks for "complaining" about not mentioning prerequisite
modules in the README or in the POD.

Dan Browning for suggestion being able to specify which text and pod files
should be changed.

=head1 COPYRIGHT

Copyright (c) 2003-2004 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<ExtUtils::MakeMaker>.

=cut
