# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get competence level object
my $CompetenceLevelObject = $Kernel::OM->Get('Kernel::System::CompetenceLevel');

# get helper object
$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);
my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

# add competence level names
my $CompetenceLevelRand = 'competence-level' . $Helper->GetRandomID();

# Tests for competence level encode method
my @Tests = (
    {
        Input => {
            Name    => $CompetenceLevelRand,
            Level   => 1,
            ValidID => 1,
            UserID  => 1,
        },
        Result => '',
        Name   => 'Competence level - ',
    },
);

my %FirstCompetenceLevelList;
my %CompleteCompetenceLevelList;
my %AddedCompetenceLevels;

%FirstCompetenceLevelList = $CompetenceLevelObject->CompetenceLevelList(
    Valid => 0
);

TEST:
for my $Test (@Tests) {

    # add
    my $CompetenceLevelID = $CompetenceLevelObject->CompetenceLevelAdd(
        Name    => $Test->{Input}->{Name},
        Level   => 1,
        ValidID => $Test->{Input}->{ValidID},
        UserID  => $Test->{Input}->{UserID},
    );

    $Self->IsNot(
        $CompetenceLevelID,
        $Test->{Result},
        $Test->{Name} . 'Add',
    ) || next TEST;

    $FirstCompetenceLevelList{$CompetenceLevelID} = $Test->{Input}->{Name};

    # get
    my %ResultGet = $CompetenceLevelObject->CompetenceLevelGet(
        ID     => $CompetenceLevelID,
        UserID => 1,
    );

    # compare results
    $Self->Is(
        $ResultGet{ID},
        $CompetenceLevelID,
        $Test->{Name} . 'Get Correct ID',
    ) || next TEST;

    $Self->Is(
        $ResultGet{ValidID},
        $Test->{Input}->{ValidID},
        $Test->{Name} . 'Get Correct ValidID',
    ) || next TEST;

    $Self->Is(
        $ResultGet{Name},
        $Test->{Input}->{Name},
        $Test->{Name} . 'Get Correct Name',
    ) || next TEST;

    # change data
    my $NewName = $Test->{Input}->{Name} . ' - update';

    my $Valid = {
        '1' => '2',
        '2' => '3',
        '3' => '1',
    };

    my $NewValidID = $Valid->{ $ResultGet{ValidID} };

    # update data
    my $Update = $CompetenceLevelObject->CompetenceLevelUpdate(
        ID      => $CompetenceLevelID,
        Name    => $NewName,
        Level   => 1,
        ValidID => $NewValidID,
        UserID  => 1,
    );

    $Self->Is(
        $Update,
        1,
        $Test->{Name} . 'Update - Final result',
    ) || next TEST;

    my %CompetenceLevelData = $CompetenceLevelObject->CompetenceLevelGet(
        ID     => $CompetenceLevelID,
        UserID => 1,
    );

    $Self->Is(
        $CompetenceLevelData{Name},
        $NewName,
        $Test->{Name} . 'Update - get after update',
    ) || next TEST;

    $FirstCompetenceLevelList{$CompetenceLevelID} = $NewName;
}

# list
%CompleteCompetenceLevelList = ( %FirstCompetenceLevelList, %AddedCompetenceLevels );
my %LastCompetenceLevelList = $CompetenceLevelObject->CompetenceLevelList( Valid => 0 );

$Self->IsDeeply(
    \%CompleteCompetenceLevelList,
    \%LastCompetenceLevelList,
    'List - Compare complete competence level list',
);

# cleanup is done by RestoreDatabase

1;
