package Test::Input;

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

  $VERSION      = 1.01;
  @ISA          = qw(Exporter);

  @EXPORT       = qw(&IsNumber &InRange IsURL IsEmail);
  @EXPORT_OK    = ();
  %EXPORT_TAGS  = ();
}

my $EmailTestRegExp;


######################################################################################################


sub IsNumber ($)
{
  return 0 if ($_[0] !~ m/^(\d+)$/);
  return 1 if ($1 eq $_[0]);
  return 0;
}

sub InRange ($$$)
{
  return 0 if (! &IsNumber($_[0]) );
  return 0 if ($_[1] > $_[0] || $_[0] > $_[2]);
  return 1;
}

sub IsURL ($)
{
  return 1 if ($_[0] =~ m(^http\:\/\/(.+)\.(.+)$));
  return 1 if ($_[0] =~ m(^https\:\/\/(.+)\.(.+)$));
  return 0;
}

sub IsEmail ($)
{ my($Email) = @_;

  if(! defined $EmailTestRegExp)
  {
    # This regualar expression is more useful that Email::Valid,
    # E-mail valid allows all types of e-mail addresses allowed
    # by the RFC's. That includes grouping, and meta-characters.
    # This regexp however, only allows 'normal' names, followed
    # by a domainname or ipaddress,

    my $esc         = '\\\\';
    my $space       = '\040';
    my $ctrl        = '\000-\037';
    my $dot         = '\.';
    my $nonASCII    = '\x80-\xff';
    my $CRlist      = '\012\015';
    my $letter      = 'a-zA-Z';
    my $digit       = '\d';

    my $atom_char   = qq{ [^$space<>\@,;:".\\[\\]$esc$ctrl$nonASCII] };
    my $atom        = qq{ $atom_char+ };
    my $byte        = qq{ (?: 1?$digit?$digit |
                              2[0-4]$digit    |
                              25[0-5]         ) };

    my $qtext       = qq{ [^$esc$nonASCII$CRlist"] };
    my $quoted_pair = qq{ $esc [^$nonASCII] };
    my $quoted_str  = qq{ " (?: $qtext | $quoted_pair )* " };

    my $word        = qq{ (?: $atom | $quoted_str ) };
    my $ip_address  = qq{ \\[ $byte (?: $dot $byte ){3} \\] };
    my $sub_domain  = qq{ [$letter$digit]
                          [$letter$digit-]{0,61} [$letter$digit]};
    my $top_level   = qq{ (?: $atom_char ){2,4} };
    my $domain_name = qq{ (?: $sub_domain $dot )+ $top_level };
    my $domain      = qq{ (?: $domain_name | $ip_address ) };
    my $local_part  = qq{ $word (?: $dot $word )* };

    $EmailTestRegExp = qq{ $local_part \@ $domain };
  }

  $Email =~ s/("(?:[^"\\]|\\.)*"|[^\t "]*)[ \t]*/$1/g;

  return 0 if($Email !~ /^$EmailTestRegExp$/ox);
  return 1;
}


sub GetInput (&@)
{ my($CallBack, @Text) = @_;
  GETTEXT:
  {
    my @IN;
    for(my $I = 0; $I < @Text; $I=$I+2)
    {
      GETITEM:
      {
        my $HasDefault = (defined $Text[$I+1]);
        my $DefaultText = $Text[$I+1] || 'default';
        $DefaultText = 'default' if(length($DefaultText) > 8);
        printf '% -20s : ', $Text[$I] . ($HasDefault ? " ($DefaultText)" : '');
        my $IN = <STDIN>;
        chomp $IN;
        if(! $HasDefault && $IN eq '')
        {
          print "You need to enter a value!\n\n";
          redo GETITEM;
        }
        push @IN, $IN || $Text[$I+1];
      }
    }

    my $OUT = &$CallBack(@IN);
    if(defined $OUT && $OUT ne '')
    {
      print "$OUT\n\n";
      redo GETTEXT;
    }
    return @IN;
  }
}



1;


__END__

=head1 NAME

Test::Input - Tests for input validation

=head1 SYNOPSIS

  use Test::Input;

  print "A number" if(IsNumber($N));
  print "In Range" if(InRange($N, 1, 10));
  print "Is a URL" if(IsURL($URL));
  print "Mailaddr" if(isEmail($Address));


  # Console tool
  my ($PASS1, $PASS2) = GetInput
  {
    return "Password don't match!" if($_[0] ne $_[1]);
    return "Password length needs to be at lease 8 characters!" if(length($_[0]) < 8);
  }
  'Choose Password'     => undef,
  'Re-enter Password'   => undef;

  print "Password is $PASS1, retyped as $PASS2";


=head1 DESCRIPTION

This module exports testing functions that can be used to
validate the user's input.


=head2 Exported Functions

=over

=item IsNumber(Variable)

Returns True if the input is a number

=item InRange(Number, Min, Max)

Returns True if the input is a number, and it lies in the range specified by Min and Max.

=item IsURL(Location)

Tests whether the input is a reasonable webpage URL or not.

=item IsEmail(Address)

Tests if the e-mail address is an normal address.
This regular expression is based on the one found in the book
"CGI Programming with Perl", by O'Reilly. Unlike the
regular expression used in the book "Mastering Regular Expressions", by Jeffy Friedl,
this subroutine does not accept all e-mail addresses allowed by the SMTP specification.
That specification also allows these addresses, which includes some comments or group names:

  Alfred Neuman <Neuman@BBN-TENEXA>
  ":sysmail" @ Some-Group . Some-Org
  Nuhammed.(I am the Greatest) Ali @(the)Vegas.WBA

That's not an error of the author, he never intended that that regexp would be
used to validate e-mail addresses at the internet. It's just an experiment if
such a regular expression could be written.

Properly, you don't want to accept any of those e-mail addresses in your input.
This routine allows all commonly used characters, a domain name followed by
an extension of 2,3 or 4 characters. It also accepts IP address instead of domain names.

=item GetInput(&CallbackTest, $InputPrompt1 => $InputPrompt1Default, $InputPromptN => $InputPromptNDefault)

Retreives input from the user (in a console application).
The first argument referrers to a callback function (=function pointer),
the other arguments are strings containing the prompt to display, followed by
a default value (or undef).
The callback function is expected to test the input and
return undef on success.
If some if the input is not valid, a string containing an error message should be retured.
When an error message is returned, the prompt will automatically display again and ask for the input.

=back

=head1 AUTHOR

        Copyright (c) 2001,  Diederik van der Boor - All Rights Reserved

        webmaster@codingdomain.com
        http://www.codingdomain.com

=cut