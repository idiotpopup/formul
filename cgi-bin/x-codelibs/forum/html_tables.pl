##################################################################################################
##                                                                                              ##
##  >> Interface HTML Parts: Tables <<                                                          ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'html_tables.pl'} = 'Release 1.2';

LoadSupport('html_interface');


##################################################################################################
## HTML Parts

$FONT_STYLE     = qq[face="Arial, Times new Roman, Times, sans-serif" size="-1"];
$FONTEX_STYLE   = qq[face="Arial, Times new Roman, Times, sans-serif" size="3" style="font-weight: bold;"];



##################################################################################################
## Table Generators

sub print_tableheader_HTML ($@) #(STRING TableTag, HASH(Title,[Width]))
{
  print qq[    $_[0]\n];
  print qq[      <TR>\n];
  for (my $I = 1; $I < @_; $I = $I + 2)
  {
    my ($Title, $Width) = ($_[$I], $_[$I + 1]);
    print $Width ? qq[        <TH background="$IMAGE_URLPATH/header.gif" bgcolor="$TABLHEAD_COLOR" width="$Width"><FONT color="$TABLFONT_COLOR"><NOBR><SPAN class="Title">&nbsp;$Title&nbsp;</SPAN></NOBR></FONT></TH>\n]
                 : qq[        <TH background="$IMAGE_URLPATH/header.gif" bgcolor="$TABLHEAD_COLOR"><FONT color="$TABLFONT_COLOR"><NOBR><SPAN class="Title">&nbsp;$Title&nbsp;</SPAN></NOBR></FONT></TH>\n];
  }
  print qq[      </TR>\n]
}

sub print_tablecell_HTML ($$;$$) #(STRING Value, STRING Width, STRING Align, STRING HTMLFont)
{ my($Value, $Width, $Align, $HTMLFont) = @_;
  $Align    ||= 'left';
  $HTMLFont ||= 'size="2"';
  print $Width ? qq[        <TD width="$Width" bgcolor="$CELL_COLOR" align="$Align"><FONT $HTMLFont>$Value</FONT></TD>\n]
               : qq[        <TD bgcolor="$CELL_COLOR" align="$Align"><FONT $HTMLFont>$Value</FONT></TD>\n];
}


1;
