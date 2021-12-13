package HTML::EscapeASCII;

#
#       Copyright (c) 2001,  Diederik van der Boor - All Rights Reserved
#
#       webmaster@codingdomain.com
#       http://www.codingdomain.com
#

use strict;


######################################################################################################
## Make the file settings...

BEGIN
{
  use Exporter  ();
  use vars      qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

  $VERSION      = 1.00;
  @ISA          = qw(Exporter);

  @EXPORT       = qw(&FormatFieldHTML &FormatFieldText);        # By default
  @EXPORT_OK    = ();                                           # By request
  %EXPORT_TAGS  = ();                                           # By tag
}


######################################################################################################


my %ASCIIConvert=(
'"'=>'quot',
'<'=>'lt',
'>'=>'gt',
chr( 34)=>'quot',
##chr( 38)=>'amp',# This is done first, so it doesn't affect characters that have been replaced already.
chr( 60)=>'lt',
chr( 62)=>'gt',
chr(162)=>'cent',
chr(163)=>'pound',
chr(164)=>'curren',
chr(165)=>'yen',
chr(166)=>'brvbar',
chr(167)=>'sect',
chr(168)=>'uml',
chr(169)=>'copy',
chr(170)=>'ordf',
chr(171)=>'laquo',
chr(172)=>'not',
chr(173)=>'shy',
chr(174)=>'reg',
chr(175)=>'macr',
chr(176)=>'deg',
chr(177)=>'plusmn',
chr(178)=>'sup2',
chr(179)=>'sup3',
chr(180)=>'acute',
chr(181)=>'micro',
chr(182)=>'para',
chr(183)=>'midpunt',
chr(184)=>'cedil',
chr(185)=>'sup1',
chr(186)=>'ordm',
chr(187)=>'requo',
chr(188)=>'fraq14',
chr(189)=>'frac12',
chr(190)=>'frac34',
chr(191)=>'iquest',
chr(192)=>'Agrave',
chr(193)=>'Aacute',
chr(194)=>'Acirc',
chr(195)=>'Atilde',
chr(196)=>'Auml',
chr(197)=>'Aring',
chr(198)=>'AElig',
chr(199)=>'Ccedil',
chr(200)=>'Egrave',
chr(201)=>'Eacute',
chr(202)=>'Ecirc',
chr(203)=>'Euml',
chr(204)=>'lgrave',
chr(205)=>'lacute',
chr(206)=>'lcirc',
chr(207)=>'luml',
chr(208)=>'ETH',
chr(209)=>'Ntilde',
chr(210)=>'Ograve',
chr(211)=>'Oacute',
chr(212)=>'Ocirc',
chr(213)=>'Otilde',
chr(214)=>'Ouml',
chr(215)=>'times',
chr(216)=>'Oslash',
chr(217)=>'Ugrave',
chr(218)=>'Uacute',
chr(219)=>'Ucirc',
chr(220)=>'Uuml',
chr(221)=>'Yacute',
chr(222)=>'THORN',
chr(223)=>'szlig',
chr(224)=>'agrave',
chr(225)=>'aacute',
chr(226)=>'acirc',
chr(227)=>'atilde',
chr(228)=>'auml',
chr(229)=>'aring',
chr(230)=>'aelig',
chr(231)=>'ccedil',
chr(232)=>'agrave',
chr(233)=>'eacute',
chr(234)=>'ecirc',
chr(235)=>'euml',
chr(236)=>'igrave',
chr(237)=>'iacute',
chr(238)=>'icirc',
chr(239)=>'iuml',
chr(240)=>'ograve',
chr(241)=>'ntilde',
chr(242)=>'ograve',
chr(243)=>'oacute',
chr(244)=>'ocirc',
chr(245)=>'otilde',
chr(246)=>'ouml',
chr(247)=>'divide',
chr(248)=>'oslash',
chr(249)=>'ugrave',
chr(250)=>'uacute',
chr(251)=>'ucirc',
chr(252)=>'uuml',
chr(253)=>'yacute',
chr(254)=>'thorn',
chr(255)=>'yuml',
);

my %HTMLConvert = reverse %ASCIIConvert;

my $ASCIIList = '(['. join('', sort keys %ASCIIConvert) .'])';
my $HTMLList  = '('. join('|', sort keys %HTMLConvert) .')';

##################################################################################################
## HTML Escape Convert

sub FormatFieldHTML(@)
{
  foreach(@_)
  {
    s/\&/&amp;/g;
    s/$ASCIIList/\&$ASCIIConvert{$1};/g;
  }
}

sub FormatFieldText(@)
{
  foreach(@_)
  {
    s/\&$HTMLList;/$HTMLConvert{$1}/g;
    s/&amp;/&/g;
  }
}

1;


__END__

=head1 NAME

HTML::EscapeASCII - Converts special ASCII characters to HTML escape codes

=head1 SYNOPSIS

  use HTML::EscapeASCII;

  my @Fields = ('RenE<egrave>', 'Bites & bytes', 'Say <hello>');

  &FormatFieldHTML(@Fields);    # @Fields now is HTML text
  # Values: Ren&egrave;, Bites &amp; bytes, Say &lt;hello&gt;

  &FormatFieldText(@Fields);    # @Fields is restored as plain text.


=head1 DESCRIPTION

This module makes converts plain text ASCII codes into HTML escape codes.
This will be very useful when showing the text input from a user,
preventing any text evaluated as HTML codes.

=head2 Exported Functions

=over

=item FormatFieldHTML(@Array)

Converts all the items in @Array from plain ASCII into HTML escape codes where useful.

=item FormatFieldText(@Array)

Reverses the changes done by FormatFieldHTML. All HTML escape codes are
replaced by their real ASCII equivalents.

=back

=head1 AUTHOR

        Copyright (c) 2001,  Diederik van der Boor - All Rights Reserved

        webmaster@codingdomain.com
        http://www.codingdomain.com

=cut