##################################################################################################
##                                                                                              ##
##  >> Interface HTML Parts: Table Fields <<                                                    ##
##  This module is a part of the X-Forum CGI software program.                                  ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################



use strict;

$VERSIONS{'html_fields.pl'} = 'Release 1.6';

LoadSupport('html_interface');


##################################################################################################
## Should be added to every print_header_HTML call

$FORM_JS = <<FORM_JS;
    <SCRIPT language="JavaScript" type="text/javascript"><!--
      FORM_MSG_EMAIL  = "$MSG[FORM_EMAIL]";
      FORM_MSG_FILLIN = "$MSG[FORM_FILLIN]";
      FORM_MSG_INT    = "$MSG[FORM_INT]";
      FORM_MSG_UINT   = "$MSG[FORM_UINT]";
      FORM_MSG_FLOAT  = "$MSG[FORM_FLOAT]";
    // --></SCRIPT>
    <SCRIPT language="JavaScript" type="text/javascript" src="$LIBARY_URLPATH/testinput.js"></SCRIPT>
FORM_JS



##################################################################################################
## HTML Parts

$SPLIT_HTML     = qq[<TR><TD width="200" align="right" height="6" colspan="2"></TD></TR>];



##################################################################################################
## Test Field Generators for the JavaScript

sub print_required_TEST (@) #(ARRAY field names)
{
  print qq[      <INPUT type="hidden" name="test_required" value="] . join(',', @_) . qq[">\n];
}

sub print_int_TEST (@) #(ARRAY field names)
{
  print qq[      <INPUT type="hidden" name="test_int" value="] . join(',', @_) . qq[">\n];
}

sub print_uint_TEST (@) #(ARRAY field names)
{
  print qq[      <INPUT type="hidden" name="test_uint" value="] . join(',', @_) . qq[">\n];
}

sub print_float_TEST (@) #(ARRAY field names)
{
  print qq[      <INPUT type="hidden" name="test_float" value="] . join(',', @_) . qq[">\n];
}

sub print_email_TEST (@) #(ARRAY field names)
{
  print qq[      <INPUT type="hidden" name="test_email" value="] . join(',', @_) . qq[">\n];
}




##################################################################################################
## Start the <FORM tag.

sub print_inputfields_HTML ($$$;@) #(STRING Table, STRING MoreCode,BOOLEAN Secure, MoreFieldNamesN,MoreFieldValuesN)
{
  my $Table    = shift;
  my $MoreCode = shift;
  my $Secure   = shift;

  my $URL  = ($Secure? $THIS_URLSEC : $THIS_URL);
  my $MORE = ($MoreCode? qq[ $MoreCode] : '');

  print qq[    <FORM method="POST" action="$URL" onSubmit="return TestForm(this)"$MORE>\n];
  for (1..(@_/2))
  {
    my $Name  = shift;
    my $Value = shift;
    if(! defined $Name)  { $Name  = ''; }
    if(! defined $Value) { $Value = ''; }
    print qq[      <INPUT type="hidden" name="$Name" value="$Value">\n];
  }
  print qq[      $Table\n];
}




##################################################################################################
## End of the </FORM> tag

sub print_buttoncells_HTML ($$$$;@) #(STRING SubmitText,STRING MoreCode, STRING Button1Text,STRING MoreButtonCode, STRING ResetText,STRING MoreCode)
{
  # IF this subroutine gets more then 4 args (submit + reset),
  # AND the last two arguments contain undef,
  # the reset button will disappear.
  my $HasReset;
  my $SubmitText = shift;
  my $SubmitMore = shift;
  my $ResetMore  = pop;
  my $ResetText  = pop;

  # Defaul values
  if(! defined $SubmitText) { $SubmitText = 'Submit' }
  if(  defined $ResetText)  { $HasReset = 1; }

  # Have we received a reset button?
  if(@_)
  {
    $HasReset = (defined $ResetText);
  }
  else
  {
    if(! defined $ResetText) { $ResetText = 'Reset' }
    $HasReset = 1;
  }


  # More code for the submit/reset buttons?
  $SubmitMore = (defined $SubmitMore? " $SubmitMore" : '');
  $ResetMore  = (defined $ResetMore?  " $ResetMore"  : '');


  # Print submit button
  print qq[        <TR><TD width="200" align="right"></TD>]; # Empty left field
  print qq[<TD><INPUT type="submit" class="CoolButton" value="    $SubmitText    "$SubmitMore>];
  print qq[ &nbsp; ];

  # Print the other buttons in the arg list
  for (1..(@_/2))
  {
    my $ButtonText = shift;
    my $ButtonMore = shift;

    $ButtonMore = (defined $ButtonMore?   " $ButtonMore"   : q[ type="button"]);

    print qq[<INPUT class="CoolButton" value="    $ButtonText    "$ButtonMore>];
    print qq[ &nbsp; ];
  }


  # Print the reset
  if($HasReset)
  {
    print qq[<INPUT type="reset" class="CoolButton" value="    $ResetText    "$ResetMore>];
  }

  # Print te </FORM>
  print <<FORM_END;
</TD></TR>
      </TABLE>
    </FORM>
FORM_END
}



##################################################################################################
## Text Fields in the table

sub print_fieldcells_HTML ($$@) #(STRING GroupName, BOOLEAN Splitters, HASH(Title, Value))
{
  my $FirstPrint = (($_[0] || '') ne '');

  field:for (my $I = 2; $I < @_; $I = $I + 2)
  {
    next field if $_[$I + 1] eq '';

    if ($FirstPrint) { print qq[      <TR><TH width="200" bgcolor="$HEADBACK_COLOR"><FONT color="$HEADFONT_COLOR"><NOBR>$_[0]</NOBR></FONT></TH><TD></TD></TR>\n]; }
    print qq[      <TR><TD width="200" align="right" class="InputLabel" valign="top"><FONT size="2">$_[$I]:</FONT></TD><TD bgcolor="$DATABACK_COLOR"><FONT color="$DATAFONT_COLOR">$_[$I+1]</FONT></TD></TR>\n];
    $FirstPrint = 0;
  }

  print_splitcells_HTML() if($_[1]);
}


##################################################################################################
## Make a <SELECT> box

sub sprint_selectfield_HTML ($$$) # ($$\@) #(STRING FieldName, NUMBER SelectedIndex, HASH(OptionValue, OptionDisplay)) >> STRING HTML
{ my($Name, $SelectedName, $Items) = @_;

  if(! defined ref $Items) { warn "Bad arguments for sprint_selectfield_HTML\n"; }

  my $HTML = qq[\n        <SELECT name="$Name">];

  for (my $I = 0; $I < @{$Items}; $I = $I + 2)
  {
    my $Name  = @{$Items}[$I];
    my $Value = @{$Items}[$I + 1];
    $HTML .= qq[\n          <OPTION value="$Name"] . (defined $SelectedName && $Name eq $SelectedName ? ' SELECTED' : '') . qq[>$Value</OPTION>];
  }

  $HTML .= qq[\n        </SELECT>\n        ];
  return $HTML;
}


sub sprint_multiplefield_HTML ($$$$) # ($$\@\@) #(STRING FieldName, STRING Height, STRING SelectedNames, HASH(OptionValue, OptionDisplay)) >> STRING HTML
{ my($Name, $Height, $Selected, $Items) = @_;

  if(! (defined ref $Selected && defined ref $Items)) { warn "Bad arguments for sprint_multiplefield_HTML\n"; }

  $Height    ||= 4;
  my $HTML     = qq[\n        <SELECT name="$Name" MULTIPLE class="multiple" height="$Height">];
  my %Selected = map { $_ => 1 } @{$Selected};

  for (my $I = 0; $I < @{$Items}; $I = $I + 2)
  {
    my $Name  = @{$Items}[$I];
    my $Value = @{$Items}[$I + 1];
    $HTML .= qq[\n          <OPTION value="$Name"] . ($Selected{$Name} ? ' SELECTED' : '') . qq[>$Value</OPTION>];
  }

  $HTML .= qq[\n        </SELECT>\n        ];
  return $HTML;
}


##################################################################################################
## Make table cells containing input fields


sub print_editcells_HTML ($$@) #(STRING GroupName, BOOLEAN Splitters, HASH(Title, Value))
{
  print qq[        <TR><TH width="200" bgcolor="$HEADBACK_COLOR"><FONT color="$HEADFONT_COLOR"><NOBR>$_[0]</NOBR></FONT></TH><TD></TD></TR>\n] unless(($_[0] || '') eq '');
  for (my $I = 2; $I < @_; $I = $I + 2)
  {
    print qq[        <TR><TD width="200" align="right" class="InputLabel" valign="top"><FONT size="2">$_[$I]:</FONT></TD><TD>$_[$I+1]</TD></TR>\n];
  }

  print_splitcells_HTML() if($_[1]);
}


##################################################################################################
## Splitter

sub print_splitcells_HTML
{
  print qq[        $SPLIT_HTML\n];
}


##################################################################################################
## Very basic Member Information

sub print_memberinfo_HTML#()
{
  print_fieldcells_HTML($MSG[GROUP_ACCOUNTINFO] => 1,
                        $REQ_HTML.$MSG[LOGIN_ACCOUNT]  => dbGetMemberName($XForumUser));
}


##################################################################################################
## Box with member list



sub sprint_memberfield_HTML ($$;$) # ($$\@) #(STRING FieldName, STRING MultipleHeight, ARRAYREF SelectedItemNames) >> STRING HTML
{
  my($field, undef, undef) = @_;

  LoadSupport('db_groups');
  my %names = &dbGetMemberNames();
  my %lcnames = map { $_ => lc($names{$_}) } %names;
  my @list  = map
              {
                $_ => $names{$_}
              }
              sort
              {
                $lcnames{$a} cmp $lcnames{$b}
                || $a cmp $b
              }
              keys %names;
  return sprint_multiplefield_HTML($_[0], $_[1], $_[2], \@list);
}

sub sprint_groupfield_HTML ($$;$) # ($$\@) #(STRING FieldName, STRING MultipleHeight, ARRAYREF SelectedItemNames) >> STRING HTML
{
  LoadSupport('db_members');
  my %names = &dbGetGroupNames();
  my %lcnames = map { $_ => lc($names{$_}) } %names;
  my @list  = map
              {
                $_ => $names{$_}
              }
              sort
              {
                $lcnames{$a} cmp $lcnames{$b}
                || $a cmp $b
              }
              keys %names;
  return sprint_multiplefield_HTML($_[0], $_[0], $_[2], \@list);
}


1;

