#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Readonly;
use File::Copy;
use open qw< :encoding(UTF-8) >;

# Read in the SCSS file and keep track of 'sections'
# then use these sections to make a table of contents

my $dryrun  = 0;
my $verbose = 0;
my $inplace = 0;
my $file;
my $output;
GetOptions (
    'v|verbose'     => \$verbose,
    'n|dryrun'      => \$dryrun,
    'i|inplace'     => \$inplace,
    'f|file=s'      => \$file,
    'o|output=s'    => \$output,
);

die ('You need to provide a filename.') unless $file;

Readonly my $TAG                => '[\#\$\w\- ]+';
Readonly my $SHORT_TITLE        => '\/{2,}\s*(' . $TAG . ')';
Readonly my $LARGE_TITLE_EDGE   => '[\/\\][*]+[-]+[*][\\\/]';
Readonly my $LARGE_TITLE        => '(' . $TAG . ')';
Readonly my $CONTENTS_OPEN      => '/*------------------------------------*\\';
Readonly my $HEADER_OPEN        => '^\s*\/\*!\*';
Readonly my $HEADER_CLOSE       => '^\s*\*/\s*$';
Readonly my $BUFFER_DOTS        => 3;

my $max_title_length    = 20;
my $prev_line_state     = 0;
my $in_line_count       = -1;
my $in_contents         = 0;
my $in_header           = 0;
my $toc_start           = 0;
my $non_blank_line      = 0;
my @sections; # Array of sections
my @lines;

# Open the file, scan and read the whole thing into memory
my $in;
open($in, '<', $file) or die("Unable to open file '$file'");
print "Working on file: $file (v:" . $verbose . "), (d:" . $dryrun . ")\n" if $verbose;

while (<$in>) {
    $in_line_count++;
    chomp;

    $non_blank_line++ unless (m/^\s*$/);

    #
    # Handle previous ToC
    #
    if ($_ eq $CONTENTS_OPEN) {
        $in_contents = 1;
        print "Line: $in_line_count. Old ToC Start.\n" if $verbose;
        next;
    }
    if ($in_contents) {
        # First blank line ends existing ToC
        $in_contents = 0 if ($_ eq '');
        print "Line: $in_line_count. Old ToC end.\n" if $verbose;
        next;
    }

    # From this point on we know it's a line to keep
    push(@lines, $_);

    #
    # Handle top comment, e.g. WordPress style header
    #
    if (m!$HEADER_OPEN! && ($non_blank_line == 1)) {
        $in_header = 1;
        print "Line: $in_line_count. Permenant stylesheet header recognised\n" if $verbose;
        next;
    }
    if ($in_header) {
        if (m!$HEADER_CLOSE!) {
            $in_header = 0;
            $toc_start = $in_line_count + 1;
            print "Line: $in_line_count. Header end.\n" if $verbose;
        }
        next;
    }

    #
    # Handle title tags
    #

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
            print STDERR "Line: $in_line_count\tLarge Header:" . $1 . "\n" if $verbose;
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
        print STDERR "Line: $in_line_count\tShort Header:" . $1 . "\n" if $verbose;
        if (length($1) > $max_title_length) { $max_title_length = length($1) }
        push (@sections, $1);
        next;
    }

}
if ($!) {
    die "Unexpected error while reading from $file: $!";
}

close($in);

# Print table of contents header
my $toc = qq{$CONTENTS_OPEN\n}
        . qq{   CONTENTS\n}
        . qq{\\*------------------------------------*/\n}
        . qq{/**\n};

# Print each section title and trailing dots
foreach my $section_title (@sections) {
    $toc .= " * " . $section_title
      . ( '.' x (($max_title_length + $BUFFER_DOTS) - length($section_title)) )
      . "\n";
}
$toc .= " */\n\n";
print $toc if ($verbose);

# About to write some output, nows the time to bail if dry run
exit 0 if $dryrun;

unless ($output || $inplace) {
    die('No output file provided.');
}

if ($inplace) {
    copy($file, $file.'.bak') or die("Couldn't backup file before in place edit");
    $output = $file;
}

my $out;
open($out, '>', $output) or die("Couldn't open $output for writing");
for my $i (0..$#lines) {
    if ($i == $toc_start) {
        print $out $toc;
    } else {
        print $out ($lines[$i] . "\n");
    }
}
close($out);

__END__


=head1 NAME

update-toc - Add/Update a nicely formatted table of contents for a (S)CSS file

=head1 SYNOPSIS

  update-toc [-n] [-v] -f input-file [-o output-file] [-i|--inplace]

=head1 DESCRIPTION

Simple script to generate a formatted table of contents for a CSS file based
loosely on the format used by the fantastic inuit.css framework.

The script detects two different title markers in CSS, the first is large titles:
 /*------------------------------------*\
     CSS-SECTION-TITLE-HERE
 \*------------------------------------*/

The second is a shorthand version:
 // CSS-SECTION-TITLE-HERE

The output by default is:
 /*------------------------------------*\
     $CONTENTS
 \*------------------------------------*/
 /**
  * $CSS-SECTION-TITLE-HERE...
  * $OTHER-ITEM-HERE..........
  */

The script will replace an existing table of contents that fits this format.
It will also leave in place a stylesheet header, e.g. those used in WordPress
themes.

=head1 OPTIONS

=head2 C<-f|--file>

The input CSS/SCSS file to add/update the table of contents to.

=head2 C<-o|--output>

The filename to store the output to. Note that any existing file will be
clobbered. Use 'inplace' for overwriting the current input file.

=head2 C<-i|--inplace>

Use the input filename as the output filename. This causes a copy of the
input file to be made at [inputfilename].bak

=head2 C<-n|--dryrun>

Don't actual output anything to file. Most useful when used with verbose.

=head2 C<-v>

Verbose output. Useful for debugging.

=cut
