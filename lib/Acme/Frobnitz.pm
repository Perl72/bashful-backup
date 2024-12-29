package Acme::Frobnitz;

use strict;
use warnings;
use IPC::System::Simple qw(capturex);
use Cwd qw(abs_path);
use File::Spec;
use File::stat;
use File::Basename;
use FindBin;
use POSIX qw(strftime);

our $VERSION = '0.03';

sub new {
    my ($class) = @_;
    return bless {}, $class;
}



# Determine the Python interpreter path based on uname
sub _get_python_path {
    my ($class) = @_;

    # Run `uname` to detect the OS
    my $osname = qx(uname -s);
    chomp($osname);  # Remove trailing newline
    my $python_path;

    if ($osname =~ /Darwin/i) {  # macOS
        $python_path = '/Users/mymac/miniconda3/envs/new-env/bin/python';
    } elsif ($osname =~ /Linux/i) {  # Linux
        # Sample path for Linux; replace with actual path as needed
        $python_path = '/home/fritz/miniconda3/envs/new-env/bin/python';
        print "Detected Linux: Using Python path: $python_path\n";
    } else {
        die "Unsupported operating system: $osname\n";
    }

    # Validate the Python path
    unless (-x $python_path) {
        die "Python interpreter not found or not executable at: $python_path\n";
    }

    return $python_path;
}


# Find the Python script path dynamically
sub _get_script_path {
    my ($class, $script_name) = @_;
    my $base_dir = abs_path("$FindBin::Bin/.."); # One level up from bin
    my $script_path = File::Spec->catfile($base_dir, 'bin', $script_name);

    unless (-f $script_path) {
        die "Python script $script_path does not exist.\n";
    }

    return $script_path;
}

sub download {
    my ($class, $hyperlink) = @_;
    die "No hyperlink provided.\n" unless $hyperlink;

    my $script_path = $class->_get_script_path("call_download.py");
    my $python_path = $class->_get_python_path();
    print "Running command: $python_path $script_path $hyperlink\n";
    my $output;
    eval {
        $output = capturex($python_path, $script_path, $hyperlink);
    };
    if ($@) {
        die "Error executing $script_path with hyperlink $hyperlink: $@\n";
    }

    chomp($output); # Remove trailing newlines from Python output
    return $output;
}


# Add watermark by invoking the Python watermark script directly
sub add_watermark {
    my ($class, $input_video) = @_;
    die "Input video file not provided.\n" unless $input_video;

    my $script_path = $class->_get_script_path("call_watermark.py");
    my $python_path = $class->_get_python_path();
    print "Running command: $python_path $script_path $input_video\n";

    my $output;
    eval {
        $output = capturex($python_path, $script_path, $input_video);
    };
    if ($@) {
        die "Error adding watermark with $script_path: $@\n";
    }

    chomp($output); # Remove trailing newlines from Python output
    return $output;
}

sub add_basic_captions {
    my ($class, $input_video) = @_;
    die "Input video file not provided.\n" unless $input_video;


    my $script_path = $class->_get_script_path("call_ken.py");
    my $python_path = $class->_get_python_path();
    print "Running command: $python_path $script_path $input_video \n";

    my $output;
    eval {
        $output = capturex($python_path, $script_path, $input_video);
    };
    if ($@) {
        die "Error adding captions with $script_path: $@\n";
    }

    chomp($output); # Remove trailing newlines from Python output
    return $output;
}



# Verify the downloaded file
sub verify_file {
    my ($class, $file_path) = @_;
    die "File path not provided.\n" unless $file_path;

    my $abs_path = abs_path($file_path) // $file_path;
    #$DB::single = 1; 
    if (-e $abs_path) {
        print "File exists: $abs_path\n";

        # File size
        my $size = -s $abs_path;
        print "File size: $size bytes\n";

        # File permissions
        my $permissions = sprintf "%04o", (stat($abs_path)->mode & 07777);
        print "File permissions: $permissions\n";

        # Last modified time
        my $mtime = stat($abs_path)->mtime;
        print "Last modified: ", strftime("%Y-%m-%d %H:%M:%S", localtime($mtime)), "\n";

        # Owner and group
        my $uid = stat($abs_path)->uid;
        my $gid = stat($abs_path)->gid;
        print "Owner UID: $uid, Group GID: $gid\n";

        return 1; # Verification success
    } else {
        print "File does not exist: $abs_path\n";
        my $dir = dirname($abs_path);

        # Report directory details
        print "Inspecting directory: $dir\n";
        opendir my $dh, $dir or die "Cannot open directory $dir: $!\n";
        my @files = readdir $dh;
        closedir $dh;

        print "Directory contents:\n";
        foreach my $file (@files) {
            next if $file =~ /^\.\.?$/; # Skip . and ..
            my $file_abs = File::Spec->catfile($dir, $file);
            my $type = -d $file_abs ? 'DIR ' : 'FILE';
            my $size = -s $file_abs // 'N/A';
            print "$type - $file (Size: $size bytes)\n";
        }

        return 0; # Verification failed
    }
}

1; # End of Acme::Frobnitz
