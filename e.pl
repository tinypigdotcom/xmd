#!/cygdrive/c/Strawberry/perl/bin/perl
#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Data::Dumper;
use IO::File;
use Perl::Tidy;
use Text::MultiMarkdown 'markdown';

my $source_string;
my $dest_string;
my $stderr_string;
my $errorfile_string;
my $argv = "-npro";   # Ignore any .perltidyrc at this site
$argv .= " -pbp";     # Format according to perl best practices
$argv .= " -nst";     # Must turn off -st in case -pbp is specified
$argv .= " -se";      # -se appends the errorfile to stderr
$argv .= " -html";    # -se appends the errorfile to stderr
$argv .= " -ntoc";    # -se appends the errorfile to stderr
$argv .= " -pre";     # <pre> section only
$argv .= " -nnn";     # line numbers
## $argv .= " --spell-check";  # uncomment to trigger an error

my $error;
my $output;

sub output {
    $output .= join('',@_);
}

sub trim {
    $_[0] =~ s{^\s*}{};
    $_[0] =~ s{\s*$}{};
}

sub function1 {
    my $ifh = IO::File->new('example.mmd', '<');
    die if (!defined $ifh);

    my $end=0;
    my $namespace='';
    my $perl_on=0;
    my $control=0;
    while(my $line = <$ifh>) {
        chomp $line;
        $end=0;
        $control=0;
        if ( $line =~ m{^\s*<(/)?perl\b([^<]*)>\s*$} ) {
            $end = $1 ? 1 : 0;
            if(0) {
                output("\n\n{$source_string}\n\n");
                $source_string='';
            }
            elsif($end) {
                $error = Perl::Tidy::perltidy(
                    argv        => $argv,
                    source      => \$source_string,
                    destination => \$dest_string,
                    stderr      => \$stderr_string,
                    errorfile   => \$errorfile_string,    # ignored when -se flag is set
                    ##phasers   => 'stun',                # uncomment to trigger an error
                );

                if ($error) {

                    # serious error in input parameters, no tidied output
                    output("<<STDERR>>\n$stderr_string\n");
                    die "Exiting because of serious errors\n";
                }

                if ($dest_string) {
                    $namespace ||= 'new';
                    for ($dest_string) {
                        s{( class=")}{$1$namespace-}g;
                        s{<pre>}{<pre class="$namespace">}g;
                        s{<a [^>]*>[^<]*</a>}{}g;
                        s{^(\s*\d+)}{<span class="num">$1.</span>}gm;
                    }
                    output($dest_string);
                }
#                if ($stderr_string)    { output "<<STDERR>>\n$stderr_string\n" }
#                if ($errorfile_string) { output "<<.ERR file>>\n$errorfile_string\n" }
                $source_string='';
            }

            $perl_on = $end ? 0 : 1;
            $namespace = $2 || '';
            trim($namespace);
            $control=1;
        }
        next if $control;
        if ($perl_on) {
            $source_string .= "${line}\n";
        }
        else {
            output("$line\n") if $line;
        }
    }
    $ifh->close;
    my $html = markdown($output);
#    $html =~ s{>\n\n}{>\n}g;

    $ifh = IO::File->new('full_template', '<');
    die if (!defined $ifh);
    my $contents = do { local $/; <$ifh> };

    print "$contents$html";
}

sub main {
    my @argv = @_;
    function1();
    return;
}

my $rc = ( main(@ARGV) || 0 );

exit $rc;

sub directory_read {
    # example
    # my @dot_files = grep { /^\./ && -f "$some_dir/$_" } get_directory($target);
    sub get_directory {
        my ($dir) = @_;
        opendir(my $dh, $dir) || die "can't opendir $dir: $!";
        my @files = readdir($dh);
        closedir $dh;
        return @files;
    }

    my $target = $ENV{HOME};
    my @bins = grep { /^bin\d?/ && -d "$target/$_" } get_directory($target);
}


sub file_slurp {
    my $fh;
    my $contents = do { local $/; <$fh> }
}


sub infile {
    use IO::File;

    my $ifh = IO::File->new($0, '<');
    die if (!defined $ifh);

    while(<$ifh>) {
        chomp;
        print "l: $_\n";
    }
    $ifh->close;
}


sub outfile {
    use IO::File;
    my $ofh = IO::File->new('a.out', '>');
    die if (!defined $ofh);

    print $ofh "bar\n";
    $ofh->close;
}


sub timestamp {
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);

    $mon++;
    $year += 1900;

    return sprintf("%04s%02s%02s%02s%02s%02s",$year,$mon,$mday,$hour,$min,$sec);
}

