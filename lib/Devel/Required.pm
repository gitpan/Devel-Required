package Devel::Required;

# Make sure we have version info for this module
# Make sure we do everything by the book from now on

$VERSION = '0.01';
use strict;

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
#    Add final newline

        $text = join( "\n",
         map {" $_ (".($modules->{$_} || 'any').")"} sort keys %{$modules} )
          if $modules;
        $text ||= " (none)";
#        $text .= "\n";

#    Convert the README file if there is one
#    Convert the main perl module if there is supposed to be one

        _convert( 'README',"Required Modules:\n",$text,"\n\n" )
         if -e 'README';
        _convert( $pod,"=head1 REQUIRED MODULES\n","\n$text\n","\n=" )
         if $pod and -e $pod;
 
    };
} #BEGIN

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

    my ($filename,$before,$text,$after) = @_;

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
#    Close the output handle

        if (s#$before(?:.*?)$after#$before$text$after#s) {
            if ($_ eq $contents) {
            } elsif (open( OUT,">$filename" )) {
                print OUT $_;
                close OUT;

#   Else (could not open file for writing)
#    Just warn
#  Else (didn't find text marker)
#   Just warn
# Else (could not open file for reading)
#  Just warn

            } else {
                warn "Could not open $filename for writing: $!\n";
            }
        } else {
            warn "Could not find text marker in $filename\n";
        }
    } else {
        warn "Could not open $filename for reading: $!\n";
    }
} #_convert

#---------------------------------------------------------------------------

__END__

=head1 NAME

Devel::Required - Automatic update of required modules documentation

=head1 SYNOPSIS

 use ExtUtils::MakeMaker;
 eval "use Devel::Required"; # auto-update documentation if needed
 WriteMakefile (
  NAME         => "Your::Module",
  VERSION_FROM => "lib/Your/Module.pm",
  PREREQ_PM    => { 'Foo' => '1.0', 'Bar::Baz' => '0.05' }
 );

=head1 DESCRIPTION

The Devel::Required module only serves a purpose in the development environment
of an author of a CPAN module (or more precisely: a user of the
L<ExtUtils::MakeMaker> module.  It makes sure that any changes to the
required modules specified in the Makefile.PL are automatically reflected
in the README file and in the main source file (if implicitely specified).

It takes the information given with the PREREQ_PM parameter and writes this to
the README file, as well as to the POD of the file specified with the
VERSION_FROM parameter.

This module should B<only> be installed on the system of the developer.

The following files will be changed:

=over 2

=item README

The README file should exists in the current directory.  It should at least
have this marker text:

 Required Modules:            <- must start at beginning of line
                              <- empty line
                              <- another empty line

After Makefile.PL is executed (using the example of the L<SYNOPSIS>, the
above will be changed to:

 Required Modules:            <- must start at beginning of line
  Foo (1.0)                   <- added
  Bar::Baz (0.05)             <- added
                              <- empty line
                              <- another empty line

No changes will be made if the marker text is not found.

=item Module file

The file indicated with the "VERSION_FROM" parameter, will be searched for
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

=head1 COPYRIGHT

Copyright (c) 2003 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<ExtUtils::MakeMaker>.

=cut
