#!/usr/bin/perl
# --
# Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
# --
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;

use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);
use lib dirname($RealBin) . '/Kernel/cpan-lib';
use lib dirname($RealBin) . '/Custom';

use Getopt::Std;

use Kernel::System::ObjectManager;

sub PrintHelp {
    print <<"EOF";
otrs.LoaderCache.pl - Commandline interface to the
     cache of the CSS/JavaScript loading mechanism of OTRS

Usage: otrs.LoaderCache.pl -o delete|generate

Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
EOF
}

# get options
my %Opts;
getopt( 'o', \%Opts );
if ( $Opts{h} ) {
    PrintHelp();
    exit 1;
}

# create object manager

local $Kernel::OM = Kernel::System::ObjectManager->new(
    'Kernel::System::Log' => {
        LogPrefix => 'OTRS-otrs.Test',
    },
);

# create needed objects

if ( $Opts{o} && lc( $Opts{o} ) eq 'delete' ) {
    print "Deleting all Loader cache files...\n";
    my @DeletedFiles = $Kernel::OM->Get('Kernel::System::Loader')->CacheDelete();
    if (@DeletedFiles) {
        print "The following files were deleted:\n\t";
        print join "\n\t", @DeletedFiles;
        print "\n";
    }
    else {
        print "No file was deleted.\n";
    }
    exit 0;
}
if ( $Opts{o} && lc( $Opts{o} ) eq 'generate' ) {
    print "Generating loader cache files...\n";

    # Force loader also on development systems where it might be turned off.
    $Kernel::OM->Get('Kernel::Config')->Set(
        Key   => 'Loader::Enabled::JS',
        Value => 1,
    );
    $Kernel::OM->Get('Kernel::Config')->Set(
        Key   => 'Loader::Enabled::CSS',
        Value => 1,
    );
    my @FrontendModules = $Kernel::OM->Get('Kernel::System::Loader')->CacheGenerate();
    for my $FrontendModule (@FrontendModules) {
        print "    $FrontendModule\n";

    }
    print "Done.\n";
    exit 0;
}
else {
    PrintHelp();
}

exit 1;
