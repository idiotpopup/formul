##################################################################################################
##                                                                                              ##
##  >> XBBC interpreter <<                                                                      ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'xbbc_convert.pl'} = 'Release 1.6';

use HTML::EscapeASCII;


sub XBBC_UNKNOWN_IGNORE_CLOSE(){ 1 }  # When an unknown code is found,
                                      # Dont look for a closing code.




##################################################################################################
## XBBC Code Settings


# Define the variables we'll use.
use vars qw(%Smileys %XBBCOpenCodes %XBBCCloseCodes @XBBCInlineCodes);      # Import of settings
my(%XBBCInlineCodes);                                                       # XBBC codes
my(@ReplaceSmileys, @ReplacePicture, @OriginalSmiley, %SmileyStartBadChar); # Smileys
my(@ReplaceWords, @ReplaceParts, @Replacements, %CensorReplace);            # Bad words

XBBC_LoadSettings();
XBBC_ExamineCensoredWords();
XBBC_ExamineSmileys();
XBBC_ExamineInlineCodes();

undef %Smileys;
undef %CensorReplace;
undef @XBBCInlineCodes;


# Regexps we pre-declare
# !! I stil can't pre-declare one of the other regexps used in a s/// statement !!
my $RE_LINES      = qr/( )*($LINEBREAK_PATTERN)/;  # Empty spaces at the end of a line
my $RE_EMPTY_ATTR = qr/ (\w*)=""/;                 # Empty tags in HTML code, like <IMG src="">





##################################################################################################
## Smiley Convert

sub ReplaceSmileyCheck
{ my($Before, $I) = @_;

  return $ReplacePicture[$I] if not defined $Before;
  if($Before =~ m/^&[a-z]+/ && $SmileyStartBadChar{$I}) {
    return "$Before$OriginalSmiley[$I]";
  }
  return "$Before$ReplacePicture[$I]";
}


sub SplitParamList
{ my($paramlist) = @_;
  return split(/\,/, $paramlist) if(index($paramlist, '&quot;') == -1);
  $paramlist =~ s/&quot;/"/g; # "
  $paramlist =~ s/\|/\\\|/g;
  $paramlist =~ s/((?:^|,)"[^"]*),([^"]*"(?:,|$))/$1|$2/g;
  my @splitted_text = split(",", $paramlist);
  foreach(@splitted_text)
  {
    s/"([^"]*[^\\])\|([^"]*)"/$1,$2/g;
    s/\\\|/\|/g;
    s/^"([^,]*)"$/$1/;
    $paramlist =~ s/"/&quot;/g; # "
  }
  return @splitted_text;
}





##################################################################################################
## XBBC Parser

my $InTable  = 0;
my $InCode   = 0;
my $NoMarkup = 0;
my $DoMarkup = 1;
my @XBBCBlockCodes;
my $Topic;
my $Posts;

sub ReplaceXBBCCodes
{ my $InnerText = shift;
  my $LineBreak = shift || '';

  if($InnerText =~ m[^\/])
  {
    # Closing tag
    my $XBBCCode = $XBBCBlockCodes[-1];
    if (defined $XBBCCode)
    {
      my $EndTag = $XBBCCloseCodes{$XBBCCode};
      if (defined $EndTag)
      {
        if($InnerText eq '/nomarkup' && $InCode <= 0)
        {
          if ($NoMarkup > 0) { $NoMarkup--; }
          else               { $EndTag .= qq[<FONT color="red">XBBC Error: [/nomarkup] found but not opened</FONT>]; }
          $DoMarkup = ($NoMarkup <= 0);
        }
        elsif($InnerText eq '/code' && $NoMarkup <= 0)
        {
          if ($InCode > 0) { $InCode--; }
          else             { $EndTag .= qq[<FONT color="red">XBBC Error: [/code] found but not opened</FONT>]; }
          $DoMarkup = ($InCode <= 0);
        }
        elsif($XBBCCode eq 'table' && $InTable > 0)
        {
          $InTable--;
        }

        if($DoMarkup)
        {
          $LineBreak = '' if($XBBCInlineCodes{$XBBCCode});
          pop @XBBCBlockCodes;
          return $EndTag.$LineBreak;
        }
      }
      else
      {
        pop @XBBCBlockCodes;
      }
    }
    else
    {
      pop @XBBCBlockCodes;
    }
  }
  else
  {
    my ($XBBCCode, $ParamList) = ($InnerText =~ m/([^=]+)(?:=(.+))?/);
        $XBBCCode =~ tr|A-Z|a-z|;
    my $Tag = $XBBCOpenCodes{$XBBCCode};

    if(defined $Tag)
    {
      push(@XBBCBlockCodes, $XBBCCode) if (defined $XBBCCloseCodes{$XBBCCode});
      $LineBreak = ''                  if ($XBBCInlineCodes{$XBBCCode} && $DoMarkup);

      if($DoMarkup)
      {
        if(($XBBCCode eq 'row' || $XBBCCode eq '|') && $InTable <= 0)
        {
          if (defined $XBBCCloseCodes{$XBBCCode} && @XBBCBlockCodes > 0) { $XBBCBlockCodes[-1] = undef; }
          return qq{<FONT color="#FF0000">[$InnerText]</FONT>$LineBreak};
        }
        elsif($XBBCCode eq 'table')
        {
          $InTable++;
        }
      }

      if($XBBCCode eq 'nomarkup')
      {
        if($InCode <= 0)
        {
          $NoMarkup++;
          $DoMarkup = 0;
          if($NoMarkup > 1) { return "[$InnerText]".$LineBreak }
          else              { return $Tag.$LineBreak           }
        }
        else
        {
          return "[$InnerText]".$LineBreak
        }
      }
      elsif($XBBCCode eq 'code')
      {
        if($NoMarkup <= 0)
        {
          $InCode++;
          $DoMarkup = 0;
          if($InCode > 1) { return "[$InnerText]".$LineBreak }
          else            { return $Tag.$LineBreak           }
        }
        else
        {
          return "[$InnerText]".$LineBreak
        }
      }
      elsif (defined $ParamList && length($ParamList) && $DoMarkup)
      {
        # Split parameters into array
        my @ParamList = SplitParamList($ParamList);


        if($XBBCCode eq 'image' || $XBBCCode eq 'url')
        {
          if($ParamList[0] =~ m/^www\./)
          {
            $ParamList[0] = "http://$ParamList[0]";
          }
          elsif($ParamList[0] =~ m/^javascript:/)
          {
            $LineBreak = qq{ <FONT color="#FF0000"><CODE>[$XBBCCode=$ParamList]</CODE></FONT>$LineBreak};
            if (defined $XBBCCloseCodes{$XBBCCode} && @XBBCBlockCodes > 0) { $XBBCBlockCodes[-1] = undef; }
            return qq[<IMG src="$IMAGE_URLPATH/icons/error.gif" width="16" height="16" alt="$MSG[XBBC_NOJSURL]">$LineBreak];
          }
        }
        elsif ($XBBCCode eq 'quotepost')
        {
          XBBC_HandleQuotePost(@ParamList);
        }

        # The tag contains parameters
        # Substitute %PARAM(index)% from XBBC->HTML code definition for params of comma separated list
        my $I = 1;
        replaceparam:while($Tag =~ s/%PARAM$I%/$ParamList[$I-1]/g)
        {
          last replaceparam if (not defined $ParamList[$I]);
          $I++;
        }
        $Tag =~ s/ \w+="%PARAM\d+%"//g;
        $Tag =~ s/%PARAM\d+%//g;
      }
      elsif($DoMarkup)
      {
        $Tag =~ s/ \w+="%PARAM\d+%"//g;
        $Tag =~ s/%PARAM\d+%//g;
      }

      return $Tag.$LineBreak if $DoMarkup;
      return "[$InnerText]".$LineBreak;
    }
  }
  return "[$InnerText]$LineBreak";
}

sub XBBC_HandleQuotePost
{
  if ($_[0] =~ m/^(\d+)$/
  && (defined $Topic))
  {
    LoadSupport('db_posts');
    LoadSupport('db_members');

    my @PostInfo;

    if(defined $Posts) { (@PostInfo)        = dbGetPostInfo($Posts,   $_[0]) }
    else               { (undef, @PostInfo) = dbGetPostNoTest($Topic, $_[0]) }

    if (@PostInfo)
    {
      # Yes! it's a number and could be a post index number!
      if($PostInfo[DB_POST_TITLE] ne '')
      {
        $PostInfo[DB_POST_DATE] = DispTime($PostInfo[DB_POST_DATE]);
        my $Name = dbGetMemberName($PostInfo[DB_POST_POSTER], 0);
        my $Page = dbGetPostPage($_[0]);

        $_[0] = qq[<NOBR>$MSG[POST_QUOTE1] $PostInfo[DB_POST_DATE],</NOBR> ]
              . qq[<NOBR>] . sprint_memberlink_HTML($PostInfo[DB_POST_POSTER]) . " "
              . qq[$MSG[POST_QUOTE2]:</NOBR> ]
              . qq[<NOBR>(<A href="$THIS_URL?show=topic&page=$Page&topic=$Topic#post$_[0]">$MSG[POST_QUOTE3]</A>)</NOBR>]
                unless($Name eq '');
        return;
      }
    }
  }
  $_[0] = $MSG[POST_QUOTE4];
}


sub FormatFieldXBBC ($;$$) #(STRING HTMLContents, STRING TopicID) >> STRING FormattedContents
{ my ($Contents, $TopicParam, $PostParam) = @_;

  # XBBC Processing
  my $Pos1     = -1;
  my $Pos2     = -1;


  # Convert ASCII codes to HTML escape codes.
  # Then Adjust the URL's and codes
  # Finally, replace double spaces.
  FormatFieldHTML($Contents);
  FormatURLCodes($Contents);
  $Contents =~ s/$RE_LINES/\n/g;
#  $Contents =~ s/  /&nbsp; /g;
#  $Contents =~ s/\t/&nbsp; /g;



  # Replace smileys
  foreach my $I (0..@ReplaceSmileys-1)
  {
    $Contents =~ s~(\&[a-z]+)?$ReplaceSmileys[$I]~ReplaceSmileyCheck($1, $I)~eg


    # The following line is no longer used, since it gives problems with escaped ASCII codes
    # like while($read = <FH>) becomes while($read = &lt;FH&gt;), which includes a ;) smiley.
    # $Contents =~ s~$ReplaceSmileys[$I]~$ReplacePicture[$I]~g

    # Alternative code:
    # $Contents =~ s~[^\&a-z{2}]{1}$ReplaceSmileys[$I]~$ReplacePicture[$I]~g
  }


  if($ALLOW_XBBC)
  {
    # Reset global variables
    $InTable        = 0;
    $InCode         = 0;
    $NoMarkup       = 0;
    $DoMarkup       = 1;
    @XBBCBlockCodes = ();

    # Replace XBBC codes
    $Topic         = $TopicParam;
    $Posts         = $PostParam;

    $Contents      =~ s/\[(.+?)\](\n)?/ReplaceXBBCCodes($1, $2)/eg;

    $Topic         = undef;
    $Posts         = undef;



    # If there are still closing tags found in the buffer, add them now to the code
    while (@XBBCBlockCodes)
    {
      my $XBBCCode = pop (@XBBCBlockCodes);
      if(defined $XBBCCode)
      {
        if ($XBBCCode eq 'code')
        {
          $InCode--;
          if ($InCode == 0)
          {
            my $EndTag = $XBBCCloseCodes{$XBBCCode};
            $Contents .= $EndTag if (defined $EndTag);
          }
        }
        elsif ($XBBCCode eq 'nomarkup')
        {
          $NoMarkup-- ;
          if ($NoMarkup == 0)
          {
            my $EndTag = $XBBCCloseCodes{$XBBCCode};
            $Contents .= $EndTag if (defined $EndTag);
          }
        }
        else
        {
          my $EndTag = $XBBCCloseCodes{$XBBCCode};
          $Contents .= $EndTag if (defined $EndTag);
        }
      }
    }
  }

  # Then convert bad words...
  foreach my $I (0..@ReplaceWords - 1) { $Contents =~ s-$ReplaceWords[$I]-$1$Replacements[$I]$2-ig; }
  foreach my $I (0..@ReplaceParts - 1) { $Contents =~ s-$ReplaceParts[$I]-$Replacements[$I]-ig; }

  # And Finally convert remaining line breaks.
  $Contents =~ s/\n/<BR>\n            /g;

  # Dump debug code if available.
  return $Contents;
}




##################################################################################################
## Build up the regexp to find URL codes in the XBBC codes

my $NoXBBCURL1 = '([\n\b]|\A|[^\w])';                 # [end of line OR: word boundary] OR: 'begin of string'
my $NoXBBCURL2 = '([\n\b]|\A|[^/:.(://\w+)])';        # OR: [not: ....... ]
my $BeforeURL1 = '([\n\b]|\A|[^"=\[\]\w])';           # [end of line OR: word boundary] OR: 'begin of string'
my $BeforeURL2 = '([\n\b]|\A|[^"=\[\]/:.(://\w+)])';  # OR: [not: ....... ]
my $Proto1     = '\w+://';                            # http://, ftp://
my $Proto2     = 'www\.[^.]';                         # www. (but not www..)
my $Domain     = '[\w\~;:$\-+!*?/=&@#%.,]+';          # One of these: a-z A-Z _ ; : $ - + * ? / = & @ # % . ,
my $Rest       = '[\w\~;:$\-+!*?/=&@#%]{2,}';         # One of these: a-z A-Z _ ; : $ - + * ? / = & @ # %      (at least 2 times)
my $Sep        = '\.';                                # splits domain.rest
my $URL1       = "($Proto1$Domain$Sep$Rest)";         # http://www.url.com
my $URL2       = "($Proto2$Domain$Sep$Rest)";         # www.url.com

##################################################################################################
## Check the URL codes

sub FormatURLCodes
{
  if($ALLOW_XBBC)
  {
    my $ExitCode = '\[/.*?\]';
    my $EndCode  = '[/]';
    my $EndCodeT = '[/code]';

    # Convert URL's
    $_[0] =~ s<\[url\](.+?)$ExitCode>               # [url]http://www.site.com[/...]
              <\[url=$1]$1$EndCode>ig;              # [url=http://www.site.com]http://www.site.com[/]

    $_[0] =~ s<\[email\](.+?)$ExitCode>             # [email]you@there.com[/...]
              <\[email=$1]$1$EndCode>ig;            # [email=you@there.com]you@there.com[/]

    $_[0] =~ s<\[url=mailto:(.+?)\](.+?)$ExitCode>  # [url=mailto:you@there.com]you[/...]
              <[email=$1]$2$EndCode>sig;            # [email=you@there.com]you[/]

    # Limit the smiley URL to default characters.
    $_[0] =~ s<\[smiley=([a-z0-9]*[^a-z0-9]+[a-z0-9]*)?\]>
              <\[image=$IMAGE_URLPATH/icons/error.gif,16,16]>ig;

    # Convert URL's without XBBC codes to [url] codes
    $_[0] =~ s~$BeforeURL1\\*$URL1~$1\[url=$2\]$2$EndCode~isg;
    $_[0] =~ s~$BeforeURL2\\*$URL2~$1\[url=http://$2\]$2$EndCode~isg;
  }
  else
  {
    $_[0] =~ s~$NoXBBCURL1\\*$URL1~$1<A href="$2" target="_blank">$2</A>~isg;
    $_[0] =~ s~$NoXBBCURL2\\*$URL2~$1<A href="http://$2" target="_blank">$2</A>~isg;
  }
}



##################################################################################################
## Extra subs

sub XBBC_LoadSettings
{
  # Release 1.5 Revision1: Test for odd number of elements. (caused "use of undef value in line 320")
  require "$DATA_FOLDER${S}settings${S}xbbccodes.cfg";
  my @CensorReplace = dbGetFileContents("$DATA_FOLDER${S}settings${S}$LANGUAGE.cen", FILE_NOERROR);
  if((@CensorReplace % 2) != 0)
  {
    for(my $I = 0; $I < @CensorReplace - 1; $I+=2)
    {
      $CensorReplace{$CensorReplace[$I]} = $CensorReplace[$I + 1];
    }
    $CensorReplace{$CensorReplace[-1]} = "<FONT color=red>[no censored replacement: $CensorReplace[-1]]</FONT>";
  }
  else
  {
    %CensorReplace = @CensorReplace;
  }

  delete $CensorReplace{''};
}

sub XBBC_ExamineCensoredWords
{
  while (my ($Text, $Replace) = each(%CensorReplace))
  {
    push @ReplaceWords, qr/(\W)\Q$Text\E(\W)/;    # Entire words first
    push @ReplaceParts, qr/\Q$Text\E/;            # Then parts of words
    push @Replacements, $Replace;                 # Word to replace it with
  }
}

sub XBBC_ExamineSmileys
{
  my @SortSize = sort { length $b <=> length $a } keys %Smileys;
  my $I = 0;

  foreach my $Tag (@SortSize)
  {
    my $Name = $Smileys{$Tag};
    push @OriginalSmiley,         qq[$Tag];
    push @ReplaceSmileys,         qr/\Q$Tag/;
    push @ReplacePicture,         qq[<IMG src="$IMAGE_URLPATH/smileys/$Name.gif" border="0" width="16" alt="$Name">];
    $SmileyStartBadChar{$I} = 1 if($Tag =~ m/^\;/);
    $I++;
  }
}

sub XBBC_ExamineInlineCodes
{
  # Convert the XBBC inline codes
  %XBBCInlineCodes = map { $_=>1 } @XBBCInlineCodes;
}

1;
