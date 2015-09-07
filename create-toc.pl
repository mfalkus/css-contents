#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Readonly;

# Read in the SCSS file and keep track of 'sections'
# then use these sections to make a table of contents

my $dryrun = 0;
my $verbose = 0;
my $file;
GetOptions (
    'v|verbose' => \$verbose,
    'd|dryrun'  => \$dryrun,
    'f|file=s'  => \$file,
);

print "V: " . $verbose . " Dryrun: " . $dryrun . "\n";

Readonly my $TAG                => '[\#\$\w\- ]+';
Readonly my $SHORT_TITLE        => '\/{2,}\s*(' . $TAG . ')';
Readonly my $LARGE_TITLE_EDGE   => '[\/\\][*]+[-]+[*][\\\/]';
Readonly my $LARGE_TITLE        => '(' . $TAG . ')';
Readonly my $BUFFER_DOTS        => 3;

my $max_title_length = 20;
my $prev_line_state = 0;
my $line_count = -1;
my @sections; # Array of sections

while (<>) {
    $line_count++;
    chomp;

    print "Line: $line_count - Prev: $prev_line_state\n";

    # Last line was the title part of a three-line title comment
    # so we can skip this line (the closing line)
    if ($prev_line_state == -1) {
        $prev_line_state = 0;
        next;
    }

    if (/$LARGE_TITLE_EDGE/) {
        $prev_line_state = 1; # Looks like this is an opening title line
        next;
    }

    if ($prev_line_state == 1) {
        if (m/$LARGE_TITLE/ ) {
            print STDERR "Line: $line_count\tLarge Header:" . $1 . "\n" if $verbose;
            if (length($1) > $max_title_length) { $max_title_length = length($1) }
            push (@sections, $1);
            $prev_line_state = -1; # Next line will be closing title
            next;

        } else {
            $prev_line_state = 0; # Next line could be a title
            next;
        }
    }

    # Detect the shorthand form of a CSS title 
    if (m/$SHORT_TITLE/) {
        print STDERR "Line: $line_count\tShort Header:" . $1 . "\n" if $verbose;
        if (length($1) > $max_title_length) { $max_title_length = length($1) }
        push (@sections, $1);
        next;
    }

}

# We're done if dryrun mode is enabled
exit 0 if $dryrun;

# Print table of contents header
print qq{
/*------------------------------------*\
    \$CONTENTS
\*------------------------------------*/
/**
};

# Print each section title and trailing dots
foreach my $section_title (@sections) {
    print " * " . $section_title
      . ( '.' x (($max_title_length + $BUFFER_DOTS) - length($section_title)) )
      . "\n";
}

# Print closing comment for T.O.C.
print " */\n";

__END__

=head1 NAME

generate-css-toc - Output a nicely formatted table of contents from a SCSS file

=head1 SYNOPSIS

  generate-css-toc [-d]

=head1 DESCRIPTION

Simple script to generate a formatted table of contents for a CSS file based on
the format used by the inuit.css framework.

The script detects two different title markers in CSS, the first is the usual:
 /*------------------------------------*\
     $CSS-SECTION-TITLE-HERE>
 \*------------------------------------*/

The second is a shorthand version:
 // #CSS-SECTION-TITLE-HERE
or
 // $CSS-SECTION-TITLE-HERE

The output by default is:
 /*------------------------------------*\
     $CONTENTS
 \*------------------------------------*/
 /**
  * $CSS-SECTION-TITLE-HERE...
  * $OTHER-ITEM-HERE..........
  */

=head1 OPTIONS

=head2 C<-d>

Debug output (basically adds line numbers where the title can currently be found)
and skip outputting the formatted table of contents.

=cut
