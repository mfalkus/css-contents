#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
#use Common;

# Read in the SCSS file and keep track of 'sections'
# then use these sections to make a table of contents

my $debug = 0;
GetOptions (
    'debug' => \$debug,
);

my $prev_line_state = 0;
my $line_count = ();
my $max_title_length = 20;
my @sections; # Array of sections

while (<>) {

    $line_count++;

    # Last line was the title part of a three-line title comment
    # so we can skip this line (the closing line)
    if ($prev_line_state == -1) {
        $prev_line_state = 0;
        next;
    }

    my $css_line = $_;
    chomp $css_line;
    
    # The last line was probably an opening comment tag for a title
    if ($prev_line_state == 1) {
        if ($css_line =~ m/\$([\w\-]+)/ ) {
            print STDERR "L Line $line_count:\t" . $1 . "\n" if $debug;
            if (length($1) > $max_title_length) { $max_title_length = length($1) }
            push (@sections, $1);
            $prev_line_state = -1; # Next line will be closing title
            next;

        } else {
            $prev_line_state = 0; # Next line could be a title
            next;
        }
    }

    if ($css_line =~ m#[\/\\]\*+-+\*[\\\/]#) {
        # Looks like this is an opening title line
        $prev_line_state = 1;
        next;
    }

    # Detect the shorthand form of a CSS title 
    if ($css_line =~ m!\/{2,}\s*[\#\$]([\w\-]+)!) {
        print STDERR "S Line $line_count:\t" . $1 . "\n" if $debug;
        if (length($1) > $max_title_length) { $max_title_length = length($1) }
        push (@sections, $1);
        next;
    }

}

# We're done if debug mode is enabled
exit 0 if $debug;

# Print table of contents header
print qq{
/*------------------------------------*\
    \$CONTENTS
\*------------------------------------*/
/**
};

# Print each section title and trailing dots
foreach my $section_title (@sections) {
    print " * \$"
          . $section_title
          . ( '.' x (($max_title_length + 3) - length($section_title)) )
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
