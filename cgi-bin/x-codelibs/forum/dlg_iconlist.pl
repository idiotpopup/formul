##################################################################################################
##                                                                                              ##
##  >> Icon List for EditMember Dialog <<                                                       ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'dlg_iconlist.pl'} = 'Release 1.6';

LoadSupport('check_security');


#################################################################################################
## Check access and examine parameters

ValidateMemberCookie();

##################################################################################################
## Icon List Dialog

my $CanJS;

sub Show_IconListDialog ()
{
  # Prepare...
     $CanJS        = param('javascript');   # Provided by a test in the client browser
  my $Folder       = "$IMAGE_FOLDER${S}membericons${S}";
  my $IsIconRegExp = qr/\.(gif|jpg|png)$/;

  my @IconFiles;

  # Get the icon files
  if(opendir(ICONS, $Folder))
  {
    @IconFiles = sort grep(/$IsIconRegExp/, readdir ICONS);
    closedir(ICONS);

    if(@IconFiles == 0)
    {
      Action_Error($MSG[ICONLIST_EMPTY]);
    }
  }
  else
  {
    Action_Error("$MSG[ICONLIST_EMPTY]: $! (membericons)");
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
        if (null != window.opener && null != window.opener.document.editmbr && null != window.opener.document.editmbr.icon)
        {
          window.opener.document.editmbr.icon.value = ImageFile;
          window.close();
        }
        else
        {
          alert('$MSG[ICONLIST_FAIL1]\\n$MSG[ICONLIST_FAIL2] (' + ImageFile + ') $MSG[ICONLIST_FAIL3]');
        }
      }
    // --></SCRIPT>
ICON_JAVASCRIPT
  }


  # Print header...
  print_header;
  print_smalldlg_HTML();
  print_header_HTML($MSG[SUBTITLE_ICONLIST], $MSG[SUBTITLE_ICONLIST], undef, $JS);
  print_bodystart_HTML();


  # Print a description what to do.
  if ($CanJS)
  {
    print '    ' . $MSG[ICONLIST_HOWTO1] . "<BR>\n";
    print '    ' . $MSG[ICONLIST_HOWTO2] . "<BR>\n";
  }
  else
  {
      print <<ICON_HEADER_HTML;
    <NOSCRIPT>
      $MSG[ICONLIST_NOJS]
    </NOSCRIPT>
ICON_HEADER_HTML
  }



  # Init for icon loop.
  my $PrevSubject = '';
  my $I = 0;

  my @Ungroupped;

  icon:foreach my $File (@IconFiles)
  {
    # Get the names
    my ($FileTitle, $Subject, $Sep, $Name, $DisplayName, $Extension) = IconListExtractFields($File);

    if($Subject eq '')
    {
      push @Ungroupped, $File;
      next icon;
    }

    IconListCheckForNewSubject($Subject, $PrevSubject, $I);
    IconListWriteIcon($File, $Subject, $Sep, $Name, $DisplayName);
    IconListCheckForNewRow($I);
    $I++;
  }

  if ($PrevSubject ne '')
  {
    # End of the table
    print qq[      </TR>\n];
    print qq[    </TABLE>\n];
  }

  icon:foreach my $File (@Ungroupped)
  {
    my ($FileTitle, $Subject, $Sep, $Name, $DisplayName, $Extension) = IconListExtractFields($File);

    $Subject = "?";
    IconListCheckForNewSubject($Subject, $PrevSubject, $I);
    IconListWriteIcon($File, $Subject, $Sep, $Name, $DisplayName);
    IconListCheckForNewRow($I);
    $I++;
  }

  if ($PrevSubject ne '')
  {
    # End of the table
    print qq[      </TR>\n];
    print qq[    </TABLE>\n];
  }
  else
  {
    # If we never found a subject, we assume the iconlist is empty
    print "<P>Error: $MSG[ICONLIST_EMPTY]!</P>\n";
  }

  # Footer...
  print_footer_HTML();
}


sub IconListExtractFields
{ my($File) = @_;

  my($FileTitle, $Extension) = $File      =~ m/^(.+)\.(.+?)$/;
  $Extension   = ''    unless defined $Extension;
  $FileTitle   = $File unless defined $FileTitle;

  my($Subject, $DisplayName) = $FileTitle =~ m/^(.+?)\-(.+)$/;
  $Subject     = ''         unless defined $Subject;
  $DisplayName = $FileTitle unless defined $DisplayName;

  my $Sep;
  if($Subject eq '')
  {
    # Attempt to make subjects out of numbered icons
    ($Subject, $DisplayName) = $FileTitle =~ m/^(.+?)(\d+)$/;
    $Subject     = ''         unless defined $Subject;
    $DisplayName = $FileTitle unless defined $DisplayName;
    $Sep = '';
  }
  else
  {
    $Sep = '-';
  }

  my $Name  = ($Extension eq 'gif' ? $FileTitle : $File);
  $DisplayName =~ s/\-/ /g  if $CanJS;

  return ($FileTitle, $Subject, $Sep, $Name, $DisplayName, $Extension);
}

sub IconListWriteIcon
{ my($File, $Subject, $Sep, $Name, $DisplayName) = @_;
  print qq[        <TD width="16%" align="center">];
  print qq[<A href="javascript:LoadImage('$Name');">] if ($CanJS);
  {
    print qq[<IMG src="$IMAGE_URLPATH/membericons/$File" border="1" title="$Name"><BR>]
        . qq[<FONT size="1" color="$FONT_COLOR"><NOSCRIPT>$Subject$Sep</NOSCRIPT>$DisplayName</FONT>];
  }
  print qq[</A>] if ($CanJS);
  print qq[</TD>\n];
}

sub IconListCheckForNewSubject
{ my($Subject, $PrevSubject, $I) = @_;

  # If this is a new iconlist, end the current table.
  if (lc($PrevSubject) ne lc($Subject))
  {
    if ($PrevSubject ne '')
    {
      print qq[        <TD width="16%"></TD>\n] foreach ($I..5);  # Spacer
      print qq[      </TR>\n]
          . qq[    </TABLE>\n];
    }

    print qq[    <P><HR width="50%" align="left" color="$POSTBODY_COLOR" size="5"><BR>\n]
        . qq[    <B>$Subject</B><P>\n]
        . qq[    <TABLE width="100%" align="center" cellpadding="5">\n]
        . qq[      <TR>\n];


    $_[1] = $Subject;  # $PrevSubject = $Subject;
    $_[2] = 0;         # $I = 0;
  }
}

sub IconListCheckForNewRow
{ my($I) = @_;
  print qq[      </TR><TR>\n] if ((($I+1) % 6) == 0);
}

1;
