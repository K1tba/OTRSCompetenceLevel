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
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Cache',
    'Kernel::System::CompetenceLevel',
    'Kernel::System::DB',
    'Kernel::System::Group',
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

    my %DataList;
    my $Translation;

    if ( $Self->{ConfigItem}->{PrefKey} eq 'UserCompetencieGroups' ) {
        %DataList =  $Kernel::OM->Get('Kernel::System::Group')->GroupList(
            Valid => 1,
        );
        $Param{Name} = 'Groups';
    }

    if ( $Self->{ConfigItem}->{PrefKey} eq 'UserCompetencieRoles' ) {
        %DataList = $Kernel::OM->Get('Kernel::System::Group')->RoleList(
            Valid => 1,
        );
        $Param{Name} = 'Roles';
    }

    if ( $Self->{ConfigItem}->{PrefKey} eq 'UserCompetenciePrioritys' ) {
        %DataList = $Kernel::OM->Get('Kernel::System::Priority')->PriorityList(
            Valid => 1,
        );
        $Param{Name} = 'Prioritys';
        $Translation = 1;
    }

    if ( $Self->{ConfigItem}->{PrefKey} eq 'UserCompetencieQueues' ) {
        %DataList = $Kernel::OM->Get('Kernel::System::Queue')->QueueList(
            Valid => 1,
        );
        $Param{Name} = 'Queues';
    }

    if ( $Self->{ConfigItem}->{PrefKey} eq 'UserCompetencieTypes' ) {
        %DataList = $Kernel::OM->Get('Kernel::System::Type')->TypeList(
            Valid => 1,
        );
        $Param{Name} = 'Types';
    }

    my %CompetenceLevelList = $Kernel::OM->Get('Kernel::System::CompetenceLevel')->CompetenceLevelList(
        Valid => 1,
    );

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $PrefKey = $Self->{ConfigItem}->{PrefKey};
    if ( $Param{UserData}->{$PrefKey} ) {

        my $Data = $Kernel::OM->Get('Kernel::System::JSON')->Decode(
            Data => $Param{UserData}->{$PrefKey},
        );

        if ( $Data ) {
            for my $Key ( sort keys %{ $Data } ) {

                my $Value = $Translation
                    ? $LayoutObject->{LanguageObject}->Translate( $DataList{$Key} )
                    : $DataList{$Key};

                my $CompetenceLevel
                    = $LayoutObject->{LanguageObject}->Translate( $CompetenceLevelList{$Data->{$Key}} );

                $LayoutObject->Block(
                    Name => 'BodyRow',
                    Data => {
                        ValueID             => $Key,
                        ValueName           => $Value,
                        CompetenceLevelID   => $Data->{$Key},
                        CompetenceLevelName => $CompetenceLevel,
                    },
                );

                delete $DataList{$Key};
            }
        }
    }

    $CompetenceLevelList{0} = '-';

    # build competence level string
    $Param{DefaultCompetenceLevelOption} = $LayoutObject->BuildSelection(
        Data         => \%CompetenceLevelList,
        Name         => 'DefaultCompetenceLevel' . $Param{Name},
        ID           => 'DefaultCompetenceLevel' . $Param{Name},
        Class        => 'W100pc Modernize',
        SelectedID   => 0,
        Translation  => 1,
    );

    $DataList{0} = '-';

    # build competence level string
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
