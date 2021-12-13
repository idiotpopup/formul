package Test::IPAddress;

#
#       Copyright (c) 2001,  Diederik van der Boor - All Rights Reserved
#
#       webmaster@codingdomain.com
#       http://www.codingdomain.com
#

use strict;
use 5.005;


######################################################################################################
## Make the file settings...

BEGIN
{
  use Exporter  ();
  use vars      qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

  $VERSION      = 1.00;
  @ISA          = qw(Exporter);

  @EXPORT       = qw( &ClientIP &IsIP &IsIPBlock &IsClientIP &IsLocalIP &IsIPInBlock );
  @EXPORT_OK    = ();
  %EXPORT_TAGS  = ();
}

my @IP_VARS = (
                'HTTP_X_FORWARDED_FOR',
                'HTTP_CLIENT_IP',
                'X_CLIENT_IP',
                'REMOTE_ADDR',
              );

my $LocalIP = '127.0.0.1';
my $IP      = $LocalIP;

ip:foreach my $Var (@IP_VARS)
{
  my $EnvVar = $ENV{$Var};
  if(defined $EnvVar
  && $EnvVar ne $LocalIP)
  {
    $IP = $EnvVar;
    last ip;
  }
}


my $byte       = '(?:[01]?\d?\d|2[0-4]\d|25[0-5])';
my $IP4        = qr/$byte\.$byte\.$byte\.$byte/;
my $LocalIP    = qr/\Q$LocalIP/;
my $ClientIP   = qr/\Q$IP/;


sub ClientIP ()    { return $IP                            }
sub IsIP ($)       { return $_[0] =~ m/^$IP4$/        ?1:0 }

sub IsLocalIP ($)  { return $_[0] =~ m/^$LocalIP$/    ?1:0 }
sub IsClientIP (@) { return IsIPInBlock($IP, @_)           }

sub IsIPBlock ($)
{ my($IP) = @_;

  $IP =~ s/\*/0/g;
  return IsIP($IP);
}

sub IsIPInBlock ($@)
{ my($IP, @IPBlocks) = @_;
  # Sample: IsIPInBlock('154.244.0.21', '154.*.*.*');

  return 0 if ! IsIP($IP);

  if(@IPBlocks)
  {
    @IPBlocks = map
                {
                  s/\./\\./g;    # Replace . with \.
                  s/\*/.+/g;     # Replace * with .+
                  qr/^$_$/;      # Make the regexp
                }
                @IPBlocks;

    my $I=1;
    foreach my $IPRegExp (@IPBlocks)
    {
      return $I if ($IP =~ m/$IPRegExp/);
      $I++;
    }
  }

  return 0;
}

1;


__END__

=head1 NAME

Test::IPAddress - Working with IP addresses

=head1 SYNOPSIS

  use Test::IPAddress;

  print "The client IP address is: " . ClientIP();  # for CGI programs


  my @BanBlocks = ('255.33.*.*', '146.45.0.1', '143.44.*.*');

  if(IsClientIP(@BanBlocks))
  {
    print "You're banned!";
    exit;
  }

  my $BlockNum = IsClientIP(@BanBlocks);
  if($BlockNum)
  {
    print "Your IP block ($BanBlocks[$BlockNum-1]) is banned!";
    exit;
  }



=head1 DESCRIPTION

This module can be used to check IP addresses,
and it can also find out the client IP address
in a CGI environment, based on environment variables
used by various webservers.

=head1 SUBROUTINES

=over

=item IsIP(IPAddress)

Tests whether the string is an IP address (###.###.###.###).

=item IsIPBlock(IPAddress)

Tests whether the string is an IP block (###.###.###.### or ###.*.*.*).

=item IsLocalIP(IPAddress)

Compares the string with the local IP address (127.0.0.1).

=item IsIPInBlock(IPAddress, IPBlock1, IPBlock2, IPBlockN)

Compares the IP address with the IP blocks.
Returns the block number that matched the IP address.
Returns 0 on failure (false)

Sample:

  my $IP = '243.56.22.111';
  my $Block = IsIPInBlock($IP, '127.*.*.*', '255.33.*.*');

  if($Block) { print "The IP $IP is in block $Block" }
  else       { print "The IP does not match any block!" }

=item ClientIP()

Returns the IP address of the client, based on
various IP environment variables.
This can properly be used only in CGI environments.

=item IsClientIP(IPBlocks)

Compares the string with the client IP address.
This can properly be used only in CGI environments.

=back

=head1 AUTHOR

    Copyright (c) 2001,  Diederik van der Boor - All Rights Reserved

    webmaster@codingdomain.com
    http://www.codingdomain.com

=cut