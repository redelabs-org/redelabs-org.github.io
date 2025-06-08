#!/usr/bin/perl
use strict;
use warnings;
use utf8;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $file_path = $ARGV[0];
my $action_taken_message = ""; # To store messages like "Cleaned", "No change", "No wrapper"

if (not defined $file_path) {
    print STDERR "cleanup_pandoc_divs.pl: No file specified. Nothing to do.\n";
    # Script will naturally exit 0
} elsif (not -f $file_path) {
    print STDERR "cleanup_pandoc_divs.pl: File not found: $file_path. Nothing to do for this file.\n";
    # Script will naturally exit 0
} else {
    my $content = "";
    # Let Perl die naturally if open for read fails, this is an unrecoverable error for this op
    open my $fh_read, "<:utf8", $file_path or die "cleanup_pandoc_divs.pl: Could not open $file_path for reading: $!";
    { local $/; $content = <$fh_read>; } # Slurp file
    close $fh_read;

    my $original_content = $content;
    my $frontmatter = "";
    my $body = $content;

    if ($body =~ s/(\A---.*?^---\s*[\r\n]+)//ms) {
        $frontmatter = $1;
    } else {
        print STDERR "Warning: No YAML frontmatter detected in $file_path. Processing entire file as body.\n";
        $frontmatter = ""; # Ensure it's empty if no frontmatter found
    }

    # Body now contains content after frontmatter (or whole content if no frontmatter)
    my $original_body_state = $body; # Preserve state after frontmatter removal

    # Patterns to match for the opening fenced div.
    # Capture group 1: leading whitespace (if any) INCLUDING newlines from frontmatter
    # Capture group 2: the div line itself (::: {attrs})
    # Capture group 3: the newline(s) immediately after the div line
    my @opening_patterns = (
        qr/(\A[[:space:]]*)(:::\s*\{[^\}\n]*?\.field-item[^\}\n]*?\.even[^\}\n]*?property="content:encoded"[^\}\n]*?\})(\s*[\r\n]+)/m,
        qr/(\A[[:space:]]*)(:::\s*\{[^\}\n]*?\.field-item[^\}\n]*?\.even[^\}\n]*?\})(\s*[\r\n]+)/m,
        qr/(\A[[:space:]]*)(:::\s*\{[^\}\n]*?\.field-item[^\}\n]*?\})(\s*[\r\n]+)/m,
        qr/(\A[[:space:]]*)(:::\s*\{[^\}\n]*?\.field[^\}\n]*?\.field-name-body[^\}\n]*?\})(\s*[\r\n]+)/m,
        qr/(\A[[:space:]]*)(:::\s*\{[^\}\n]*?\.node[^\}\n]*?\.content[^\}\n]*?\})(\s*[\r\n]+)/m,
        qr/(\A[[:space:]]*)(:::\s*\{[^\}\n]*?\.content[^\}\n]*?\})(\s*[\r\n]+)/m,
        qr/(\A[[:space:]]*)(:::\s*\{\s*#_mcePaste\s*\})(\s*[\r\n]+)/m
    );

    my $body_modified_by_pattern = 0;
    my $leading_ws_before_div = "";
    my $matched_opening_div_line = "";
    my $newlines_after_div_line = "";

    foreach my $pattern (@opening_patterns) {
        if ($body =~ m/$pattern/) {
            $leading_ws_before_div = $1 // "";
            $matched_opening_div_line = $2 // ""; # The ::: {attrs} line
            $newlines_after_div_line = $3 // "";   # Newlines after div line

            # Remove the matched opening div structure
            $body =~ s/\Q$matched_opening_div_line\E\Q$newlines_after_div_line\E//; # Remove specific match

            # Now remove the *next* standalone ::: line from the modified $body
            if ($body =~ s/^[ \t]*:::[ \t]*[\r\n]?//m) {
                 $body_modified_by_pattern = 1; # Both opening and closing removed
            } else {
                print STDERR "Warning: Matched opening div '$matched_opening_div_line' but could not find a subsequent standalone ':::' line in $file_path. Reverting opening div removal.\n";
                # Revert: put back the opening div and its leading/trailing newlines
                $body = $matched_opening_div_line . $newlines_after_div_line . $body;
                $body_modified_by_pattern = 0; # Mark as not changed by pattern
            }
            last;
        }
    }

    # Restore any leading whitespace that was before the div pattern (or before the body if no pattern matched)
    $body = $leading_ws_before_div . $body;

    # Normalize trailing whitespace and ensure a single newline for the final body
    $body =~ s/[[:space:]]+\Z//;
    if ($body ne "" || $frontmatter ne "") {
      $body .= "\n" unless $body =~ /\n\Z/ && $body ne "\n"; # Add if not already ending with one, or if body became single newline
      $body =~ s/\n\n\Z/\n/s;
      if ($body eq "\n" && $frontmatter eq "") { $body = "";} # Empty file if all was whitespace
    }

    my $new_content = $frontmatter . $body;

    if ($new_content ne $original_content) {
        open my $out_fh, ">:utf8", $file_path or die "cleanup_pandoc_divs.pl: Could not open $file_path for writing: $!";
        print $out_fh $new_content;
        close $out_fh;
        if ($body_modified_by_pattern) {
            $action_taken_message = "Cleaned fenced div wrapper in: $file_path\n";
        } else {
            # This means only whitespace normalization occurred if $new_content ne $original_content
            $action_taken_message = "Normalized whitespace or minor changes in: $file_path\n";
        }
    } else {
        if ($body_modified_by_pattern) {
            $action_taken_message = "No effective change (fenced div removed but content was equivalent to original after ws normalization): $file_path\n";
        } else {
            $action_taken_message = "No targeted fenced div wrapper found or removed in: $file_path\n";
        }
    }
    print $action_taken_message;
}
# Perl script naturally exits 0 here if no 'die' was encountered.
