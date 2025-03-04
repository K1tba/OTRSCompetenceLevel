# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Output::HTML::Preferences::CompetenceLevel;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::CompetenceLevel',
    'Kernel::System::Group',
    'Kernel::System::JSON',
    'Kernel::System::Priority',
    'Kernel::System::Queue',
    'Kernel::System::Service',
    'Kernel::System::SLA',
    'Kernel::System::Type',
    'Kernel::System::User',
    'Kernel::System::Web::Request',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    for my $Needed (qw(UserID ConfigItem)) {
        die "Got no $Needed!" if ( !$Self->{$Needed} );
    }

    return $Self;
}

sub Param {
    my ( $Self, %Param ) = @_;

    my @Params = ();

    # check needed param, if no user id is given, do not show this box
    if ( !$Param{UserData}->{UserID} ) {
        return ();
    }

    # get needed objects
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my %DataList;
    my $Translation;
    my $PrefKey = $Self->{ConfigItem}->{PrefKey};

    # get groups data
    if ( $PrefKey eq 'UserCompetencieGroups' ) {
        %DataList = $Kernel::OM->Get('Kernel::System::Group')->PermissionUserGet(
            UserID => $Param{UserData}->{UserID},
            Type   => 'ro',
        );
        $Param{Name} = 'Groups';
    }

    # get roles data
    elsif ( $PrefKey eq 'UserCompetencieRoles' ) {
        %DataList = $Kernel::OM->Get('Kernel::System::Group')->PermissionUserRoleGet(
            UserID => $Param{UserData}->{UserID},
        );
        $Param{Name} = 'Roles';
    }

    # get priorities data
    elsif ( $PrefKey eq 'UserCompetenciePriorities' ) {
        %DataList = $Kernel::OM->Get('Kernel::System::Priority')->PriorityList(
            Valid => 1,
        );
        $Param{Name} = 'Priorities';
        $Translation = 1;
    }

    # get queues data
    elsif ( $PrefKey eq 'UserCompetencieQueues' ) {
        %DataList = $Kernel::OM->Get('Kernel::System::Queue')->GetAllQueues(
            UserID => $Param{UserData}->{UserID},
        );
        $Param{Name} = 'Queues';
    }

    # get types data
    elsif ( $PrefKey eq 'UserCompetencieTypes' ) {
        %DataList = $Kernel::OM->Get('Kernel::System::Type')->TypeList(
            Valid => 1,
        );
        $Param{Name} = 'Types';
    }

    # get services data
    elsif ( $PrefKey eq 'UserCompetencieServices' ) {

        # if Ticket::Service is disabled
        # do not show this box
        if ( !$ConfigObject->Get('Ticket::Service') ) {
            return ();
        }

        %DataList = $Kernel::OM->Get('Kernel::System::Service')->ServiceList(
            KeepChildren => $ConfigObject->Get('Ticket::Service::KeepChildren') // 0,
            Valid        => 1,
            UserID => 1,
        );
        $Param{Name} = 'Services';
    }

    # get SLAs data
    elsif ( $PrefKey eq 'UserCompetencieSLAs' ) {

        # if Ticket::Service is disabled
        # do not show this box
        if ( !$ConfigObject->Get('Ticket::Service') ) {
            return ();
        }

        %DataList = $Kernel::OM->Get('Kernel::System::SLA')->SLAList(
            UserID => 1,
        );
        $Param{Name} = 'SLAs';
    }

    # get a list of competence levels
    my %CompetenceLevelList = $Kernel::OM->Get('Kernel::System::CompetenceLevel')->CompetenceLevelList(
        Valid => 1,
    );

    # check if the user already has the specified competence level data
    if ( $Param{UserData}->{$PrefKey} ) {
        my $Data = $Kernel::OM->Get('Kernel::System::JSON')->Decode(
            Data => $Param{UserData}->{$PrefKey},
        );

        if ( $Data ) {
            KEY:
            for my $Key ( sort keys %{ $Data } ) {
                next KEY if !$DataList{$Key};

                my $Value = $Translation
                    ? $LayoutObject->{LanguageObject}->Translate( $DataList{$Key} )
                    : $DataList{$Key};

                my $CompetenceLevel
                    = $LayoutObject->{LanguageObject}->Translate( $CompetenceLevelList{$Data->{$Key}} );

                # create an HTML block to display the string
                $LayoutObject->Block(
                    Name => 'BodyRow',
                    Data => {
                        ValueID             => $Key,
                        ValueName           => $Value,
                        CompetenceLevelID   => $Data->{$Key},
                        CompetenceLevelName => $CompetenceLevel,
                    },
                );

                # remove the item from the list of available values,
                # as it has already been processed
                delete $DataList{$Key};
            }
        }
    }

    # build competence level string
    $CompetenceLevelList{0} = '-';
    $Param{DefaultCompetenceLevelOption} = $LayoutObject->BuildSelection(
        Data         => \%CompetenceLevelList,
        Name         => 'DefaultCompetenceLevel' . $Param{Name},
        ID           => 'DefaultCompetenceLevel' . $Param{Name},
        Class        => 'W100pc Modernize',
        SelectedID   => 0,
        Translation  => 1,
    );

    # build competence level string
    $DataList{0} = '-';
    $Param{DefaultValueOption} = $LayoutObject->BuildSelection(
        Data         => \%DataList,
        Name         => 'DefaultValue' . $Param{Name},
        ID           => 'DefaultValue' . $Param{Name},
        Class        => 'Modernize',
        SelectedID   => 0,
        Translation  => $Translation || 0,
    );

    # generate HTML
    my $Output = $LayoutObject->Output(
        TemplateFile => 'PreferencesCompetencie',
        Data         => \%Param,
    );

    push(
        @Params,
        {
            %Param,
            Block => 'RawHTML',
            HTML  => $Output,
        }
    );

    return @Params;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get array of parameter IDs
    my @IDs = $Kernel::OM->Get('Kernel::System::Web::Request')->GetArray(
        Param => 'Value'
    );

    my %DataList;
    ID:
    for my $ID ( sort @IDs ) {
        my ($Key, $Value) = split(/%%/, $ID);
        next ID if !$Key || !$Value;
        $DataList{$Key} = $Value;
    }

    my $PrefKey  = $Self->{ConfigItem}->{PrefKey};
    my $JSONData = $Kernel::OM->Get('Kernel::System::JSON')->Encode(
        Data => \%DataList,
    );

    # update user preferences
    if ( !$Kernel::OM->Get('Kernel::Config')->Get('DemoSystem') ) {
        $Kernel::OM->Get('Kernel::System::User')->SetPreferences(
            UserID => $Param{UserData}->{UserID},
            Key    => $PrefKey,
            Value  => $JSONData // '',
        );
    }

    $Self->{Message} = Translatable('Preferences updated successfully!');
    return 1;
}

sub Error {
    my ( $Self, %Param ) = @_;

    return $Self->{Error} || '';
}

sub Message {
    my ( $Self, %Param ) = @_;

    return $Self->{Message} || '';
}

1;
