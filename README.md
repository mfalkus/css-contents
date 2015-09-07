Css-Contents
============

Simple script to generate a formatted table of contents for a CSS file based on the format used by the inuit.css framework.

## What the script does

The script detects two different title markers in CSS, the first is the usual:
```css
 /*------------------------------------*\
     CSS-SECTION-TITLE-HERE
 \*------------------------------------*/
```

The second is a shorthand version:
```css
 // #CSS-SECTION-TITLE-HERE
```

The output by default is:
```css
 /*------------------------------------*\
     CONTENTS
 \*------------------------------------*/
 /**
  * CSS-SECTION-TITLE-HERE...
  * OTHER-ITEM-HERE..........
  */
```

Simple stuff but I've found it to be really useful when you're making a lot of changes to a stylesheet and aren't keeping the TOC of up to date.

## Example usage

    # To output a table of contents to STDOUT
    cat my-stylesheet.css | ./create-toc.pl

    # To see which lines are triggering a section title run with -d
    # See the perldoc for more information on this output
    cat my-stylesheet.css | ./create-toc.pl -d

## To Do

I'll probably add a flag that allows the table of contents to be prepended to the current stylesheet, or perhaps substituted for #TOC# or similar.
