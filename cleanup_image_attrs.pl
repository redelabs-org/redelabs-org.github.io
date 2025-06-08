#!/usr/bin/perl
use strict;
use warnings;
use utf8;

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $file_path = $ARGV[0];
my $action_taken = 0;

if (not defined $file_path) {
    print STDERR "cleanup_image_attrs.pl: No file specified.\n";
    # Perl will exit 0 by default if script finishes here
} elsif (not -f $file_path) {
    print STDERR "cleanup_image_attrs.pl: File not found: $file_path\n";
    # Perl will exit 0 by default
} else {
    $action_taken = 1; # File exists, will attempt to process
    my $content = "";
    {
        local $/;
        open my $fh, "<:utf8", $file_path or die "cleanup_image_attrs.pl: Could not open $file_path for reading: $!";
        $content = <$fh>;
        close $fh;
    }
    my $original_content = $content;

    # Regex:
    # Capture group $1: The entire valid Markdown image up to the closing parenthesis of the URL: !\[[^\]]*\]\([^)]*\)
    # \s*: Optional whitespace
    # \{: A literal opening curly brace
    # [^}]*: Anything that is not a closing curly brace (the attributes themselves)
    # \}: A literal closing curly brace
    $content =~ s/(\!\[[^\]]*\]\([^)]*\))\s*\{[^}]*\}/$1/g;

    if ($content ne $original_content) {
        open my $out_fh, ">:utf8", $file_path or die "cleanup_image_attrs.pl: Could not open $file_path for writing: $!";
        print $out_fh $content;
        close $out_fh;
        print "Cleaned image attributes in: $file_path\n";
    } else {
        print "No image attributes found or changed in: $file_path\n";
    }
}
# If $action_taken is 0, script already printed to STDERR and will exit 0.
# If $action_taken is 1, processing was attempted, and script will exit 0 if no 'die'.
