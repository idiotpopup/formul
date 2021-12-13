##################################################################################################
##                                                                                              ##
##  >> Smiley List for Post Dialog <<                                                           ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_smileylist.pl'} = 'Release 1.6';

use vars qw(%Smileys %XBBCOpenCodes %XBBCCloseCodes @XBBCInlineCodes);
require "$DATA_FOLDER${S}settings${S}xbbccodes.cfg";

%Smileys = reverse %Smileys; # Reverses key/values first!!


##################################################################################################
## Icon List Dialog

sub Show_SmileyListDialog ()
{
  # Prepare...
  my $CanJS       = param('javascript');   # Provided by a test in the client browser
  my $Folder      = "$IMAGE_FOLDER${S}smileys${S}";
  my $IsGIFRegExp = qr/\.gif$/;
  my @IconFiles;

  # Get the icon files
  if(opendir(ICONS, $Folder))
  {
    @IconFiles = sort grep(/$IsGIFRegExp/, readdir ICONS);
    closedir(ICONS);

    if(@IconFiles == 0)
    {
      Action_Error($MSG[SMILEYLIST_EMPTY]);
    }
  }
  else
  {
    Action_Error("$MSG[SMILEYLIST_EMPTY]: $! (smileys)");
  }


  # Load some JavaScript codes that are used to automatically select the icon
  my $JS = undef;
  if ($CanJS)
  {
    $JS = <<ICON_JAVASCRIPT;
    <SCRIPT language="JavaScript" type="text/javascript"><!--
      function LoadImage(ImageFile)
      {
        // This test for null can be programmed like this; the next item is not executed when the prev is false, so we don't get expected object errors.
        if (null != window.opener && null != window.opener.XBBC_AddCode)
        {
          window.opener.XBBC_AddCode(ImageFile);
          window.close();
        }
        else
        {
          alert('$MSG[SMILEYLIST_FAIL1]\\n$MSG[SMILEYLIST_FAIL2] "' + ImageFile + '" $MSG[SMILEYLIST_FAIL3]');
        }
      }
    // --></SCRIPT>
ICON_JAVASCRIPT
  }


  # Print header...
  print_header;
  print_smalldlg_HTML();
  print_header_HTML($MSG[SUBTITLE_SMILEYLIST], $MSG[SUBTITLE_SMILEYLIST], undef, $JS);
  print_bodystart_HTML();


  # Print a description what to do.
  if ($CanJS)
  {
    print "    $MSG[SMILEYLIST_HOWTO1]<BR>\n";
    print "    $MSG[SMILEYLIST_HOWTO2]<BR>\n";
  }
  else
  {
      print <<ICON_HEADER_HTML;
    <NOSCRIPT>
      $MSG[SMILEYLIST_NOJS]
    </NOSCRIPT>
ICON_HEADER_HTML
  }


  # Init for icon loop.
  my $IconsPrinted = 0;
  my $Row1Printed  = 0;

  my $half = (@IconFiles/2);

  for(my $I = 0; $I < $half; $I++)
  {
    file:foreach my $File ($IconFiles[$I], $IconFiles[$I + $half + 1])
    {
      next file if not defined $File;

      # Get the names
      my $Subject = substr($File, 0, index($File, '-'));
      my $Name    = substr($File, 0, rindex($File, '.'));
      my $Code    = $Smileys{$Name} || "[smiley=$Name]";

      # If this is a new iconlist, end the current table.
      if(! $IconsPrinted)
      {
        print qq[    <P>\n];
        print qq[    <TABLE width="300" align="center" cellpadding="5" bgcolor="$CELL_COLOR">\n];
        $IconsPrinted = 1;
      }


      # Print the icon, and a link if we can use javascript
      if($Row1Printed) { print qq[      </TD><TD width="20" align="center">]; }
      else             { print qq[      <TR><TD width="20" align="center">]; }

      $Code =~ s/\'/\\\'/g;

      print qq[<A href="javascript:LoadImage('$Code');">] if ($CanJS);
      {
        print qq[<IMG src="$IMAGE_URLPATH/smileys/$File" border="0" width="16" alt="$Name: $Code">];
        print qq[</A>] if ($CanJS);
        print qq[</TD><TD width="100" align="left">];
        print qq[<A href="javascript:LoadImage('$Code');">] if ($CanJS);
        print qq[<FONT color="$FONT_COLOR">$Name</FONT>];
        print qq[</A>] if ($CanJS);
      }

      if($Row1Printed) { print qq[</TD></TR>\n]; }
      $Row1Printed = !$Row1Printed;
    }
  }


  if ($IconsPrinted)
  {
    if($Row1Printed) { print qq[</TD><TD>&nbsp;</TD><TD>&nbsp;</TD></TR>\n]; }

    # End of the table
    print qq[    </TABLE>\n];
    print qq[    </P>\n];
  }
  else
  {
    # If we never found a subject, we assume the iconlist is empty
    print "<P>Error: $MSG[SMILEYLIST_EMPTY]!</P>\n";
  }

  # Footer...
  print_footer_HTML();
}

1;
