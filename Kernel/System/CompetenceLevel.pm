# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::CompetenceLevel;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Cache',
    'Kernel::System::DB',
    'Kernel::System::Log',
    'Kernel::System::Valid',
);

=head1 NAME

Kernel::System::CompetenceLevel - competence level lib

=head1 DESCRIPTION

All competence level functions. E. g. to add competence level or other functions.

=head1 PUBLIC INTERFACE

=head2 new()

Don't use the constructor directly, use the ObjectManager instead:

    my $CompetenceLevelObject = $Kernel::OM->Get('Kernel::System::CompetenceLevel');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{CacheType} = 'CompetenceLevel';
    $Self->{CacheTTL}  = 60 * 60 * 24 * 20;

    return $Self;
}

=head2 CompetenceLevelAdd()

Add a competence level.

    my $ID = $CompetenceLevelObject->CompetenceLevelAdd(
        Name    => '1 very low',
        Level   => 1,
        ValidID => 1,
        UserID  => 123,
    );

=cut

sub CompetenceLevelAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Name Level ValidID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # insert into database
    return if !$DBObject->Do(
        SQL => 'INSERT INTO competence_level (name, level, valid_id, '
            . ' create_time, create_by, change_time, change_by)'
            . ' VALUES (?, ?, ?, current_timestamp, ?, current_timestamp, ?)',
        Bind => [
            \$Param{Name}, \$Param{Level}, \$Param{ValidID}, \$Param{UserID}, \$Param{UserID},
        ],
    );

    # get new competence level id
    return if !$DBObject->Prepare(
        SQL   => 'SELECT id FROM competence_level WHERE name = ?',
        Bind  => [ \$Param{Name} ],
        Limit => 1,
    );

    # fetch the result
    my $ID;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $ID = $Row[0];
    }

    return if !$ID;

    # delete cache
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => $Self->{CacheType},
    );

    return $ID;
}

=head2 CompetenceLevelGet()

Get competence level attributes.

    my %CompetenceLevelData = $CompetenceLevelObject->CompetenceLevelGet(
        ID => 2,
    );

Return:

    %CompetenceLevelData = (
        ID       => 1,
        Name     => '1 very low',
        Level    => 1,
        ValidID  => '1',
        CreateTime => '2021-02-01 12:15:00',
        CreateBy   => '321',
        ChangeTime => '2021-04-01 15:30:00',
        ChangeBy   => '223',
    );

=cut

sub CompetenceLevelGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{ID} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need ID!',
        );
        return;
    }

    # check cache
    my $Cache = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type => $Self->{CacheType},
        Key  => 'CompetenceLevelGet::' . $Param{ID},
    );
    return %{$Cache} if $Cache;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # ask database
    return if !$DBObject->Prepare(
        SQL => 'SELECT id, name, level, valid_id, create_time, create_by, change_time, change_by '
            . 'FROM competence_level WHERE id = ?',
        Bind  => [ \$Param{ID} ],
        Limit => 1,
    );

    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ID}         = $Row[0];
        $Data{Name}       = $Row[1];
        $Data{Level}      = $Row[2];
        $Data{ValidID}    = $Row[3];
        $Data{CreateTime} = $Row[4];
        $Data{CreateBy}   = $Row[5];
        $Data{ChangeTime} = $Row[6];
        $Data{ChangeBy}   = $Row[7];
    }

    # set cache
    $Kernel::OM->Get('Kernel::System::Cache')->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => 'CompetenceLevelGet::' . $Param{ID},
        Value => \%Data,
    );

    return %Data;
}

=head2 CompetenceLevelUpdate()

Update a existing competence level.

    my $Success = $CompetenceLevelObject->CompetenceLevelUpdate(
        ID      => 123,
        Name    => '1 very low',
        Level   => 1,
        ValidID => 1,
        UserID  => 123,
    );

=cut

sub CompetenceLevelUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(ID Name Level ValidID UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    # get database object
    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # update the database
    return if !$DBObject->Do(
        SQL => 'UPDATE competence_level SET name = ?, level = ?, valid_id = ?, '
            . 'change_time = current_timestamp, change_by = ? WHERE id = ?',
        Bind => [
            \$Param{Name}, \$Param{Level}, \$Param{ValidID}, \$Param{UserID}, \$Param{ID},
        ],
    );

    # delete cache
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => $Self->{CacheType},
    );

    return 1;
}

=head2 CompetenceLevelList()

Get competence level list as a hash of ID, Name pairs.

    my %CompetenceLevelList = $CompetenceLevelObject->CompetenceLevelList(
        Valid => 1,   # (optional) default 1 (0|1)
    );

Return:

    %CompetenceLevelList = (
        1 => '1 very low',
        2 => '2 low',
        3 => '3 normal',
        4 => '4 high',
        5 => '5 very high',
    );

=cut

sub CompetenceLevelList {
    my ( $Self, %Param ) = @_;

    # check valid param
    if ( !defined $Param{Valid} ) {
        $Param{Valid} = 1;
    }

    # create cache key
    my $CacheKey;
    if ( $Param{Valid} ) {
        $CacheKey = 'CompetenceLevelList::Valid';
    }
    else {
        $CacheKey = 'CompetenceLevelList::All';
    }

    # check cache
    my $Cache = $Kernel::OM->Get('Kernel::System::Cache')->Get(
        Type => $Self->{CacheType},
        Key  => $CacheKey,
    );
    return %{$Cache} if $Cache;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    # create sql
    my $SQL = 'SELECT id, name FROM competence_level ';
    if ( $Param{Valid} ) {
        $SQL
            .= "WHERE valid_id IN ( ${\(join ', ', $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet())} )";
    }

    return if !$DBObject->Prepare( SQL => $SQL );

    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ $Row[0] } = $Row[1];
    }

    # set cache
    $Kernel::OM->Get('Kernel::System::Cache')->Set(
        Type  => $Self->{CacheType},
        TTL   => $Self->{CacheTTL},
        Key   => $CacheKey,
        Value => \%Data,
    );

    return %Data;
}

=head2 CompetenceLevelCalculate()

Get user competence level for ticket.

    my $TotalCompetence = $CompetenceLevelObject->CompetenceLevelCalculate(
        Ticket => { ... },
        UserID => 123,
    );

Return:

    $TotalCompetence = 123,

=cut

sub CompetenceLevelCalculate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(Ticket UserID)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my %Ticket = %{ $Param{Ticket} };

    # get user data
    my %UserData = $Kernel::OM->Get('Kernel::System::User')->GetUserData(
        UserID        => $Param{UserID},
        Valid         => 1,
        NoOutOfOffice => 1,
    );

    my %CompetenceCategories = (
        Groups    => 'GroupID',
        Roles     => 'RoleID',
        Prioritys => 'PriorityID',
        Queues    => 'QueueID',
        Types     => 'TypeID',
        Services  => 'ServiceID',
        SLAs      => 'SLAID',
    );

    # get json object
    my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');

    # for each category we define a competence value
    my $TotalCompetence = 0;

    CATEGORY:
    for my $Category ( keys %CompetenceCategories ) {
        my $UserField = 'UserCompetencie' . $Category;
        my $TicketKey = $CompetenceCategories{$Category};

        # default value
        my $CompetenceValue = 1;

        # if user settings are set for this category
        if ( $UserData{$UserField} ) {

            # determ the identifier from the ticket
            my $TicketValue = $Ticket{$TicketKey};

            next CATEGORY if !$TicketValue;

            my $Data = $JSONObject->Decode(
                Data => $UserData{$UserField},
            );

            # if there is a setting for this identifier, use it
            if ( exists $Data->{$TicketValue} ) {

                # get competence level data
                my %CompetenceLevelData = $Self->CompetenceLevelGet(
                    ID => $Data->{$TicketValue},
                );

                $CompetenceValue = $CompetenceLevelData{Level};
            }
        }

        $TotalCompetence += $CompetenceValue;
    }

    return $TotalCompetence;
}

1;

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut
