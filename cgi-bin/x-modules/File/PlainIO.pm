package File::PlainIO;
my $packagename = 'File::PlainIO';

######################################################################################
## Other imports

use strict;
use Fcntl qw(:flock :DEFAULT);
use 5.004; # Auto file unlocking

use constant SIMPLE_LINESEARCH => 1;  # Advanced search is still buggy

######################################################################################
## Global variables

my $MODE_READ      = 1;
my $MODE_WRITE     = 2;
my $MODE_RDWR      = 3;
my $MODE_WRITE_ADD = 4|$MODE_WRITE;
my $MODE_WRITE_NEW = 8|$MODE_WRITE;
my $MODE_RDWR_NEW  = 8|$MODE_RDWR;

my %RealFlags = (
                  $MODE_READ      => O_RDONLY,
                  $MODE_WRITE     => O_WRONLY,
                  $MODE_RDWR      => O_RDWR,
                  $MODE_WRITE_ADD => O_WRONLY|O_APPEND,
                  $MODE_WRITE_NEW => O_WRONLY|O_TRUNC,
                  $MODE_RDWR_NEW  => O_RDWR|O_TRUNC,
                );
my %RealFlock = (
                  $MODE_READ      => LOCK_SH, # SH
                  $MODE_WRITE     => LOCK_EX,
                  $MODE_RDWR      => LOCK_EX,
                  $MODE_WRITE_ADD => LOCK_EX,
                  $MODE_WRITE_NEW => LOCK_EX,
                  $MODE_RDWR_NEW  => LOCK_EX,
                );

my $DOUBLE_NEWLINE_CHARACTER;

######################################################################################
## Export some constants to caller package

BEGIN
{
  use vars qw($VERSION);
  $VERSION = 1.02;
}

sub import
{
  my $class = shift;
  my $pkg   = caller()."::";
  {
    no strict 'refs';
    my $SUB_MODE_READ      = $pkg."MODE_READ";      *$SUB_MODE_READ      = sub(){$MODE_READ};
    my $SUB_MODE_WRITE     = $pkg."MODE_WRITE";     *$SUB_MODE_WRITE     = sub(){$MODE_WRITE};
    my $SUB_MODE_RDWR      = $pkg."MODE_RDWR";      *$SUB_MODE_RDWR      = sub(){$MODE_RDWR};
    my $SUB_MODE_WRITE_ADD = $pkg."MODE_WRITE_ADD"; *$SUB_MODE_WRITE_ADD = sub(){$MODE_WRITE_ADD};
    my $SUB_MODE_WRITE_NEW = $pkg."MODE_WRITE_NEW"; *$SUB_MODE_WRITE_NEW = sub(){$MODE_WRITE_NEW};
    my $SUB_MODE_RDWR_NEW  = $pkg."MODE_RDWR_NEW";  *$SUB_MODE_RDWR_NEW  = sub(){$MODE_RDWR_NEW};
  }
}


######################################################################################
## Constructor

sub new ($$;$$)
{
  my $classname = shift;
  my ($FileName, $Mode, $ErrorMsg, $FileShouldExist) = @_;
  die "Usage: new $packagename(\$filename, MODE_constant)".CallerLocation() unless(@_ >= 2);

  # We don't allow these things:
  #   $x = PackageName::new();
  #   $y = $x->new();

  if(! defined $classname) { die "Syntax error: Class name expected after new".CallerLocation() }
  if(  ref     $classname) { die "Syntax error: Can't construct new ".ref($classname)." from another object".CallerLocation() }


  # Determine open and locking modes
  if(! defined $Mode)  { die "Sytax error: Bad file mode used".CallerLocation() }

  my $Flags = $RealFlags{$Mode};
  my $Lock  = $RealFlock{$Mode};
  if(! defined $Flags) { die "Sytax error: Bad file mode used".CallerLocation() }
  $Flags |= O_CREAT unless $FileShouldExist || $Mode==$MODE_READ;


  # Open the file
  local *HANDLE;
  my $fh = *HANDLE;
  if(sysopen($fh, $FileName, $Flags))
  {
    flock($fh, $Lock);

    # In case someone added some lines
    # while we were waiting to get the lock...
    seek($fh, 0, 2) if $Mode == $MODE_WRITE_ADD;
  }
  else
  {
    if($ErrorMsg)
    {
      while(chomp $ErrorMsg) {}
      die "$ErrorMsg: $!\n" ;
    }
    return undef;
  }

  # Instance fields
  my $this         = {};
  $this->{_FILE}   = $FileName;
  $this->{_HANDLE} = $fh;
  $this->{_MODE}   = $Mode;

  # Make the object 'self-aware';
  bless $this, $classname;           # Double argument version to enable Inheritance ;-)
  return $this;
}


######################################################################################
## Basic properties

sub filename ($)
{
  my $this = self(shift);
  return $this->{_FILE};
}

sub mode ($)
{
  my $this = self(shift);
  return $this->{_MODE};
}


######################################################################################
## More info

sub stat ($)
{
  my($this, $handle) = self(shift);
  die 'Usage: @statInfo = $FileObj->stat()'.CallerLocation() unless wantarray;
  return CORE::stat($handle);
}


######################################################################################
## Misc

sub close ($)
{
  my($this, $handle) = self(shift);
  return CORE::close($handle);
}

sub unlink ($)
{
  my $this = self(shift);
  my $handle = $this->{_HANDLE};
  if(defined fileno $handle) { CORE::close($handle) }
  CORE::unlink $this->{_FILE} or return undef;
}

######################################################################################
## Reading from the file

sub read ($;$)
{
  my($this, $handle) = self(shift);
  my($Bytes) = @_;
  die "Can't read from a write only file handle".CallerLocation() unless $this->{_MODE} & $MODE_READ;

  $Bytes = 4096 if not defined $Bytes;
  my $Buffer = "";
  my $Length = CORE::read($handle, $Buffer, $Bytes, 0);
  return undef if not defined $Length;
  $_ = $Buffer unless wantarray;
  return $Buffer;
}

sub readall ($;$)
{
  my($this, $handle) = self(shift);
  die "Can't read from a write only file handle".CallerLocation() unless $this->{_MODE} & $MODE_READ;

  local $/ = undef;
  $_ = <$handle>;
  return $_;
}

sub readline ($)
{
  my($this, $handle) = self(shift);
  die "Can't read from a write only file handle".CallerLocation() unless $this->{_MODE} & $MODE_READ;
  my $read = scalar <$handle>;
  chomp $read if defined $read;
  $_ = $read unless wantarray;
  return $read;
}

sub readlines ($;$$)
{
  my($this, $handle) = self(shift);
  my($linenum, $minsize) = @_;
  die "Can't read from a write only file handle".CallerLocation() unless $this->{_MODE} & $MODE_READ;
  die 'Usage: @lines = $FileObj->readlines()'.CallerLocation() unless wantarray;

  my @lines;

  if(! defined $linenum)
  {
    @lines = <$handle>;  # Slurp.
    chomp @lines;
  }
  else
  {
    if($linenum > 0)
    {
      local $_;
      while(<$handle>)
      {
        chomp;
        push @lines, $_;
        $linenum--;
        last if $linenum <= 0;
      }
    }
  }

  if ($minsize && (@lines < $minsize))
  {
    push @lines, ('') x ($minsize - @lines);
  }
  return @lines;
}


######################################################################################
## Writing to the file

sub write ($;$)
{
  my($this, $handle) = self(shift);
  my($text) = @_;
  $text = $_ if ! defined $text;
  die "Can't write at a read only file handle".CallerLocation() unless $this->{_MODE} & $MODE_WRITE;
  $text =~ s/(\015\012|\015|\012|\r)/\n/g;

  return CORE::print $handle $text;
}

sub writeline ($;$)
{
  my($this, $handle) = self(shift);
  my($text) = @_;
  $text = $_ if ! defined $text;
  die "Use of undefined value".CallerLocation() if ! defined $text;
  die "Can't write at a read only file handle".CallerLocation() unless $this->{_MODE} & $MODE_WRITE;

  $text =~ s/(\015\012|\015|\012|\r)/\n/g;
  while(chomp $text) {};
  return CORE::print $handle "$text\n";
}

sub writelines ($@)
{
  my($this, $handle) = self(shift);
  die "Can't write at a read only file handle".CallerLocation() unless $this->{_MODE} & $MODE_WRITE;

  my $Contents = "";
  my $buffersize = 4096;

  if(@_)
  {
    local $_;
    while(@_)  # while(shift) stops at an empty line!
    {
      $_ = shift;

      if(defined)
      {
        s/(\015\012|\015|\012|\r)/\n/g;
        while(chomp) {}
        $Contents .= "$_\n";
      }
      else
      {
        $Contents .= "\n";
      }
    }

    if(length($Contents) > $buffersize)
    {
      CORE::print $handle $Contents or return undef;
      $Contents = "";
    }
  }
  else
  {
    $Contents = $_;
    $Contents =~ s/(\015\012|\015|\012|\r)/\n/g;
  }

  CORE::print $handle $Contents;
  return 1;
}


######################################################################################
## Moving the read/write pointer

sub tellpos ($)
{
  my($this, $handle) = self(shift);
  return CORE::tell($handle);
}

sub seekpos ($$)
{
  my($this, $handle) = self(shift);
  my($pos) = @_;
  return CORE::seek($handle, $pos, 0);
}

sub movepos ($$)
{
  my($this, $handle) = self(shift);
  my($pos) = @_;
  return CORE::seek($handle, $pos, 1);
}

sub seekbegin ($)
{
  my($this, $handle) = self(shift);
  return CORE::seek($handle, 0, 0);
}

sub seekeof ($;$)
{
  my($this, $handle) = self(shift);
  my($pos) = @_;
  return CORE::seek($handle, $pos||0, 2);
}


######################################################################################
## Seeking a line number

sub seeklineindex ($$)
{
  return seeklineno($_[0], $_[1]+1);
}

sub seeklineno ($$)
{
  my($this, $handle) = self(shift);
  my($line) = @_;
  die "Can't read from a write only file handle".CallerLocation() unless $this->{_MODE} & $MODE_READ;
  die "Bad argument value for seekline: $line".CallerLocation()   unless $line > 0;

  my $oldpos     = tell($handle);             # Saver if things go wrong
  my $buffer     = "";                        # Initialize a buffer to read in
  my $buffersize = 4096;                      # Buffer Size, what else?
  my $lines      = 0;                         # Lines read
  my $lastpos    = 0;                         # Previous read pointer location

  CORE::seek($handle, 0, 0) or return undef;  # From begin:
  return 1 if $line == 1;                     # Line 1 ;-)


  if(SIMPLE_LINESEARCH)
  {
    while(--$line > 0 and $buffer = <$handle>) {}
    return defined $buffer;
  }


  my $rounds = 0;

  block:while (sysread $handle, $buffer, $buffersize)
  {
    my $newlines = ($buffer =~ tr/\n//);
    next block if $newlines == 0;
    my $total    = $lines + $newlines;

    if($newlines && ! defined $DOUBLE_NEWLINE_CHARACTER)
    {
      my $bytesread = ($buffersize * $rounds) + length($buffer);
      my $bytesfile = tell($handle);

      if($bytesread != $bytesfile) { $DOUBLE_NEWLINE_CHARACTER = 1 }
      else                         { $DOUBLE_NEWLINE_CHARACTER = 0 }
    }

    if($total > $line)
    {
      my $addpos  = -1; # The position
      my $inline  = 1;  # We are already in line 1 (since we search for the end)
      while(1)
      {
        $addpos = index($buffer, "\n", $addpos + 1);
        $inline++;
        if($addpos == -1) { die "There is still a bug in ${packagename}::seeklineno()" }

        if(($lines + $inline) >= $line)
        {
          my $extraoffset = 1;
             $extraoffset = ($lines + $inline) if($DOUBLE_NEWLINE_CHARACTER);

          # This postion of the previous line where index just found a \n
          seek($handle, $lastpos + $addpos + $extraoffset, 0) or die "There is still a bug in ${packagename}::seeklineno()";
          return 1;
        }
      }
    }
    $lines = $total;
    $lastpos += $buffersize;
    $rounds++;
  }

  # Not breaked out earlier.
  seek($handle, $oldpos, 0) or return undef;
  return undef;
}


######################################################################################
## Count the number of lines

sub countlines ($)
{
  my($this, $handle) = self(shift);
  die "Can't read from a write only file handle".CallerLocation() unless $this->{_MODE} & $MODE_READ;

  #while(--$line > 0 and $Buffer = <$handle>) {}
  #return defined $Buffer;

  my $oldpos     = tell($handle);             # Saver if things go wrong
  my $buffer     = "";                        # Initialize a buffer to read in
  my $buffersize = 4096;                      # Buffer Size, what else?
  my $lines      = 0;                         # Lines read
  my $lastcharNL = 0;                         # Is the last char read a Newline?

  CORE::seek($handle, 0, 0) or return undef;  # From begin:

  while (sysread $handle, $buffer, $buffersize)
  {
    $lines     += ($buffer =~ tr{\n}{});
    $lastcharNL = ($buffer =~ m{\n$});
  }

  $lines += 1 unless $lastcharNL;

  CORE::seek($handle, $oldpos, 0) or return undef;
  return $lines;
}


######################################################################################
## Useful for read/write files

sub rewind ($)
{
  my($this, $handle) = self(shift);
  return CORE::seek($handle, 0, 0);
}

sub truncate ($;$)
{
  my($this, $handle) = self(shift);
  my($pos) = @_;
  return CORE::truncate($handle, $pos||0);
}

sub clear ($)
{
  my($this, $handle) = self(shift);
  CORE::seek($handle, 0, 0)  or return undef;
  CORE::truncate($handle, 0) or return undef;
  return 1;
}

sub update ($$)
{
  # TODO: This code might be optimized some more
  #       like, check if something changed,
  #       only seek when we created that temp file, etc...

  my($this, $handle) = self(shift);
  my($updatefunc) = @_;
  die 'Usage: $FileObj->update { ... };'.CallerLocaltion() if((ref($updatefunc)||'') ne 'CODE');
  die "Can't read from a write only file handle".CallerLocation() unless $this->{_MODE} & $MODE_READ;

  my $size = (CORE::stat($handle))[7];
  return 1 if $size == 0;

  seek($handle, 0, 0) or return undef;


  if(1 || $size > 4096)
  {
    # Very large file.. we don't slurp the file
    # into system memory, but use disk space instead.

    # Temp file...
    local *TEMPCOPY;
    my $TmpFileName = $this->{_FILE} . "~";
    sysopen(TEMPCOPY, $TmpFileName, O_RDWR|O_CREAT|O_TRUNC) or return undef;
    flock(TEMPCOPY, LOCK_EX);

    # Read lines, modify them and write it into the temp file
    local $_;
    while(<$handle>)
    {
      my $removed = chomp;
      &$updatefunc();
      if($removed) { CORE::print TEMPCOPY "$_\n" unless not defined; }
      else         { CORE::print TEMPCOPY "$_"   unless not defined; }
    }

    # Now copy the information stored in the temp file to the current file
    CORE::seek(TEMPCOPY, 0, 0) or return undef;
    CORE::seek($handle,  0, 0) or return undef;
    CORE::truncate($handle, 0) or return undef;
    CORE::print $handle $_ while(<TEMPCOPY>);  # We had to code $_ here in the print statement.

    # Close and delete the temp file
    CORE::close(TEMPCOPY);
    CORE::unlink $TmpFileName;
    return 1;
  }
  else
  {
    # Slurp in everything
    my @lines = <$handle>;

    # Change some elements in the array
    local $_;
    foreach(@lines)
    {
      my $removed = chomp;
      &$updatefunc();
      if($removed) { CORE::print TEMPCOPY "$_\n" unless not defined; }
      else         { CORE::print TEMPCOPY "$_"   unless not defined; }
    }

    # Rewrite data back
    CORE::seek($handle,  0, 0) or return undef;
    CORE::truncate($handle, 0) or return undef;
    return CORE::print $handle @lines;
  }
}



######################################################################################


######################################################################################
## Destructor

sub DESTROY
{
  my $this = shift;

  my $handle = $this->{'_HANDLE'};
  if(fileno($handle))
  {
    #flock($handle, LOCK_UN);
    CORE::close($handle);
  }
}



######################################################################################
## Private subroutines

sub CallerLocation (;$)
{
  my @c=caller(($_[0]||0)+1);
  return " at $c[1] line $c[2]\n";
}

sub self ($)
{
  my $this = shift;
  if(! defined ref($this)) { die "Syntax error: Object expected".CallerLocation(+1) }
  return $this unless wantarray;
  die "Can't do anything with a closed filehandle".CallerLocation(+1) if not defined fileno $this->{_HANDLE};
  return ($this, $this->{_HANDLE});
}




######################################################################################
## POD

1;

__END__

=head1 NAME

File::PlainIO - Useful routines for file input and output with plain text files

=head1 SYNOPSIS

=begin text

  use File::PlainIO;

  # Write some data into a file
  $file1 = new File::PlainIO( "file1.txt", MODE_WRITE_NEW, "Can't write to file1.txt" );
  $file1->writeline("Hello there");
  $file1->writelines("This is a test...", "...using File::PlainIO", "The End");
  undef $file1;


  # Read one line
  $file2 = new File::PlainIO( "file2.txt", MODE_READ, "Can't open file2.txt" );
  $file2->seeklineno(3)           or die "Can't seek line 3: $!";
  $line3 = $file2->readline()     or die "Can't read line 3: $!";
  @lines = $file2->readlines(3)   or die "Can't read 3 lines: $!";
  @rest  = $file2->readlines()    or die "Can't read remaining lines: $!";
  undef $file2;


  # Update some lines
  my $changelines = sub
                    {
                       $_ = ""  if($. == 3);
                       $_ = "!" if($. == 4);
                    };
  $file3 = new File::PlainIO( "file3.txt", MODE_RDWR, "Can't open file3.txt" );
  $file3->update($changelines)    or die "Can't update lines: $!";
  undef $file3;

=end text

=head1 DESCRIPTION

This OO module contains useful methods to simplify the access to files.
The standard Perl functions are wrapped, sometimes there are extra features included.
Files are automatically opened and locked when you create a new object.

=head2 CREATING A NEW OBJECT

    $fileobj = new File::PlainIO( FILENAME, MODE[, ERROR_MSG][, SHOULD_EXIST]);

=begin text

  * Arguments:
    FILENAME       - The name of the file at the user's system
    MODE           - One of the MODE_ constants exported by this package
    ERROR_MSG      - Error message to 'die' when the file can't be opened
                     When not provided, the returned value will be undef.
    SHOULD_EXIST   - Set to true if the file should exist when opening

  * Constants:
    MODE_READ      - Open the file for read-only mode
    MODE_WRITE     - Open the file for write mode
    MODE_RDWR      - Open the file for both read/write modes
    MODE_WRITE_ADD - Open the file for append mode
    MODE_WRITE_NEW - Open the file for write mode (clears the file first)
    MODE_RDWR_NEW  - Open the file for both read/write modes (clears first)

=end text

=head2 METHOD NOTES

Most methods are wrappers for Perl file functions.
However, they usually provide extra functionality or error checking.
Except for that, some methods are easier to handle then the
standard Perl functions.

All methods will undef on failure. You can use that to check for errors, for example like this:

  $file->seekpos(34) or die "Can't seek in the file: $!";
  $file->clear()     or die "Can't clear the contents: $!";

For file-IO methods, it's very important you do so. Otherwise, you might get unexpected
program results. Some perl programs are filled with such problems. :'(

=head2 BASIC METHODS

=over

=item filename

Returns the filename used when creating the object.

=item mode

Returns the mode constant used.

=item stat()

Returns an array produced by the perl 'stat' function. Maybe this sounds
useless, but this method is added, because I don't want anyone to access
the hidden private fields. And so preventing bugs. That what OO is all about.

=item close()

Closes the file before the object is destroyed. Fortunately,
you don't need to call this method every time. Every file
opened with this module will be closed when the object is destroyed,
in other words, when the last reference to it falls out of scope.

=item unlink()

Closes the file when it's still open and removes it from the file system.

=item countlines()

Counts the number of lines in the file. This is done very efficient,
and might be very useful. Well, I already programmed the method for you ;-)
It simply counts the occurences of the newline character, *NOT* the $/ code.
Even if the last line is not terminated by a newline character, it will be added
to the returned result.

=back

=head2 METHODS FOR READING DATA

The read/write methods will use $_ a lot when that is appropriate.
In other words, you can use these coding structures as well:

=begin text

  # Reading line by line
  while(defined $file->readline())
  {
    print "Line = $_\n";
  }

  # Copying a file
  $file2->write     while         $file1->read(1024);
  $file2->writeline while defined $file1->readline;

=end text

Note that the defined statement is required here, because the readline method
returns an empty string (=false) when it find an empty line!

=over

=item read([NUMBER_OF_BYTES])

Reads a specified number of bytes from the file, or a default amount.
Normally, you'd better use other read methods provided by this package.

=item readall()

Reads all bytes from the current position in the file. This is the "slurp" reading method.

=item readline()

Reads one line from the file. That means, keeps reading until a \n or an EOF symbol is found.
The \n character is automatically removed from the line read. This is quite usefull,
but remember that en empty line results in false, within a boolean expression.
That means that "while($obj->readline())" stops when an empty line is found.
Use "while(defined $obj->readline())" instead.

=item readlines([NUMBER_OF_LINES][, MINIMAL_ARRAY_SIZE])

Returns an array with the lines read from the file.
All end-of-line characters are automatically removed from the lines.

If the NUMBER_OF_LINES parameter is specified, the function will
only read that amount of lines, or less when an EOF symbol is found.

The MINIMAL_ARRAY_SIZE parameter can be used to assure that the returned array
has a certain size. All the elements added to the array contain a zero-length string ("").
This can be quite usefull what your program uses the -w switch, and you don't want to check
all elements first. Note that, when using this function. the returned result always evaluates to true!

=back

=head2 METHODS FOR WRITING DATA

The write methods will convert the specified string,
so all line breaks are set correctly, and match the
line break type of the current OS. This can be very useful
when your CGI program writes the contents of a <TEXTAREA> field
into a text file. (That string might contain internet-linebreaks)

=over

=item write([TEXT])

Writes the text (or $_) back into the file.
No linebreaks will be removed or added.

=item writeline([LINE])

Writes one line back into the file. This method will remove
any double linebreaks at the end of the string, to avoid
any silly bugs in your program causing you to print two lines.

=item writelines(ARRAY_WITH_LINES)

Does the same thing as the writeline method, but for each element in the array.
This method is also a little more efficient when you have a large array filled with scalars.

=back

=head2 MOVING THE READ/WRITE POINTER

The methods move the pointer where the data is read from, or written at.
The methods don't need a detailed explanation, so you have to do it with this:

=begin text

    tellpos()        - Returns the current position
    seekpos(POS)     - Seeks that position
    movepos(OFFFSET) - Seeks relative from the current position
    seekbegin()      - Seeks the begin of the file
    seekeof()        - Seeks the end of the file
    seeklineindex(I) - Seeks a line, based on an array index
    seeklineno(N)    - Seeks a line, based on a natural number

=end text

=head2 READ/WRITE OPERATIONS

=over

=item rewind()

Same as seekbegin() for now. In other words,
you can start over reading the file again.

=item truncate([TO_BYTE_SIZE])

Clears the contents of the entire file. When the size argument is provided,
the file will be truncated to that size, preserving the first bytes/lines in the file.

=item clear()

Almost the same as calling the previous truncate() method without any arguments.
The difference, is the fact this method also moves the read/write pointer back
to the beginning of the file. This method should be used when working with MODE_RDWR files.

=item update(UPDATE_FUNCTION_REFERENCE)

This is a very powerful method, and very useful for update operations with read/write files.
The function will loop through the lines of the file, calling the subroutine, which reference
has been provided by the caller.

The subroutine doesn't receive any parameters. The line is provided by the $_ variable,
so it can be examined by a regexp directly. The \n character at the end has already been removed,
so don't worry about that. You can get the line number through the $. variable.
If the $_ is changed, that line in the file will change as well. If you set $_ to undef,
the line will be removed from the file.

This method will determine automatically which kind of update method is the most efficient.
That is either slurping in the entire file into memory, or using an extra temporary file
to store the result in.

Anyway, using this method saves you a lot of coding with sysopens, reading,
storing the new data elsewhere, and writing it all back in the file. An example
of this can be found at the SYNOPSIS section, at the top of this manual.

P.S. Maybe, this method can even be optimized by using tests to determine
if anything should be written back, or by remembering that the first 4765 bytes
of the file weren't changed at all. And so on. Just let me know if you can implement anything!

=back

=head1 AUTHOR

        Copyright (c) 2001,  Diederik van der Boor - All Rights Reserved

        webmaster@codingdomain.com
        http://www.codingdomain.com

=cut