##################################################################################################
##                                                                                              ##
##  >> Names for Time Elements <<                                                               ##
##  For Interal Use Only.                                                                       ##
##                                                                                              ##
##  Copyright (c) 2001 Diederik van der Boor - All Rights Reserved                              ##
##                                                                                              ##
##################################################################################################

package Time::Text::Dutch;
use strict;
use vars qw($VERSION @Days @ShortMonths @LongMonths);
$VERSION = 1.00;


##################################################################################################
## Time element names

@Days        = qw(Zo Ma Di Wo Do Vr Za);
@ShortMonths = qw(Jan Feb Mar Apr Mei Jun Jul Aug Sep Okt Nov Dec);
@LongMonths  = qw(Januari Februari Maart April Mei Juni Juli Augustus September Oktober November December);

1;

__DATA__

=head1 SYNOPSIS

  For internal use only; this package should by loaded as
  use Time::Text qw(LanguageName);

=cut