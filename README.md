CSS Contents
============

A relatively simple script to generate a formatted table of contents for a
SASS/CSS file based loosely on the format used by the inuit.css framework.

## What the script does

The script detects two different title markers in CSS, the first is the usual:
```css
 /*------------------------------------*\
     CSS-SECTION-TITLE-HERE
 \*------------------------------------*/
```

The second is a shorthand version:
```css
 // CSS-SECTION-TITLE-HERE
```

The ToC output is:
```css
 /*------------------------------------*\
     CONTENTS
 \*------------------------------------*/
 /**
  * CSS-SECTION-TITLE-HERE...
  * OTHER-ITEM-HERE..........
  */
```

Simple stuff but I've found it to be really useful when you're making a lot of
changes to a stylesheet and aren't keeping the TOC of up to date.

## Recommended/Example usage

    # Add (or update if already exists) a table of contents to our stylesheet
    ./update-toc.pl -f style.css

    # To see which lines are triggering a section title run with -v and -n
    ./update-toc.pl -n -v -f style.css

Checkout the `perldoc` for full details.
