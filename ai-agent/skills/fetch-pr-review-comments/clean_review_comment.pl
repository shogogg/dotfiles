#!/usr/bin/perl
#
# Cleans up review comment text for better readability supporting CodeRabbit output.
# Reads from stdin and writes to stdout.
#
use strict;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';

# Read all input at once
local $/ = undef;
my $text = <STDIN>;

# Remove emoji characters:
# - Characters followed by Variation Selector (U+FE0F) e.g., ‼️
# - Characters with Emoji_Presentation property e.g., 🟠
$text =~ s/.\x{FE0F}|\p{Emoji_Presentation}//g;

# Remove CodeRabbit severity badge (e.g., "_⚠️ Potential issue_ | _🟠 Major_")
$text =~ s/_[^_]*Potential issue[^_]*_\s*\|\s*_[^_]*_\s*//g;

# Remove CodeRabbit "Analysis chain" details block (not useful for review)
$text =~ s/<details>\s*<summary>\s*Analysis chain\s*<\/summary>[\s\S]*?<\/details>\s*//g;

# Remove HTML comments (e.g., <!-- fingerprinting:... -->)
$text =~ s/<!--[\s\S]*?-->\s*//g;

# Convert <details><summary>Title</summary> to "Title:" for readability
$text =~ s/<details>\s*<summary>\s*/\n/g;
$text =~ s/<\/summary>/:/g;
$text =~ s/<\/details>//g;

print $text;
