# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AdminCompetenceLevel;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject          = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject           = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LogObject             = $Kernel::OM->Get('Kernel::System::Log');
    my $CompetenceLevelObject = $Kernel::OM->Get('Kernel::System::CompetenceLevel');
    my $Notification          = $ParamObject->GetParam( Param => 'Notification' ) || '';

    # ------------------------------------------------------------ #
    # change
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Change' ) {

        my $ID   = $ParamObject->GetParam( Param => 'ID' ) || '';

        my %Data = $CompetenceLevelObject->CompetenceLevelGet(
            ID => $ID
        );

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Info => Translatable('Level competence updated!') )
            if ( $Notification && $Notification eq 'Update' );
        $Self->_Edit(
            Action => 'Change',
            %Data,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminCompetenceLevel',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # change action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ChangeAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $Note = '';
        my ( %GetParam, %Errors );
        for my $Parameter (qw(ID Name Level ValidID)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        # check for needed data
        for my $Key (qw(Name Level)) {
            if ( !$GetParam{$Key} ) {
                $Errors{$Key . 'Invalid'} = 'ServerError';
            }
        }

        # if no errors occurred
        if ( !%Errors ) {

            # update Competence
            my $Success = $CompetenceLevelObject->CompetenceLevelUpdate(
                %GetParam,
                UserID => $Self->{UserID}
            );

            if ($Success) {

                # if the user would like to continue editing the competence, just redirect to the edit screen
                if (
                    defined $ParamObject->GetParam( Param => 'ContinueAfterSave' )
                    && ( $ParamObject->GetParam( Param => 'ContinueAfterSave' ) eq '1' )
                    )
                {
                    return $LayoutObject->Redirect(
                        OP => "Action=$Self->{Action};Subaction=Change;ID=$GetParam{ID};Notification=Update"
                    );
                }

                # otherwise return to overview
                else {
                    return $LayoutObject->Redirect( OP => "Action=$Self->{Action};Notification=Update" );
                }
            }
            else {
                $Note = $LogObject->GetLogEntry(
                    Type => 'Error',
                    What => 'Message',
                );
            }
        }

        # something went wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Note
            ? $LayoutObject->Notify(
            Priority => 'Error',
            Info     => $Note,
            )
            : '';
        $Self->_Edit(
            Action => 'Change',
            %GetParam,
            %Errors,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminCompetenceLevel',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;

    }

    # ------------------------------------------------------------ #
    # add
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Add' ) {
        my %GetParam = ();
        $GetParam{Name} = $ParamObject->GetParam( Param => 'Name' );
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Self->_Edit(
            Action => 'Add',
            %GetParam,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminCompetenceLevel',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # add action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AddAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my $Note = '';
        my ( %GetParam, %Errors );
        for my $Parameter (qw(ID Name Level ValidID)) {
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        # check for needed data
        for my $Key (qw(Name Level)) {
            if ( !$GetParam{$Key} ) {
                $Errors{$Key . 'Invalid'} = 'ServerError';
            }
        }

        # if no errors occurred
        if ( !%Errors ) {

            # add competence level
            my $CompetenceLevelID = $CompetenceLevelObject->CompetenceLevelAdd(
                %GetParam,
                UserID => $Self->{UserID}
            );

            if ($CompetenceLevelID) {
                $Self->_Overview();
                my $Output = $LayoutObject->Header();
                $Output .= $LayoutObject->NavigationBar();
                $Output .= $LayoutObject->Notify( Info => Translatable('Level competence added!') );
                $Output .= $LayoutObject->Output(
                    TemplateFile => 'AdminCompetenceLevel',
                    Data         => \%Param,
                );
                $Output .= $LayoutObject->Footer();
                return $Output;
            }
            else {
                $Note = $LogObject->GetLogEntry(
                    Type => 'Error',
                    What => 'Message',
                );
            }
        }

        # something went wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $Note
            ? $LayoutObject->Notify(
            Priority => 'Error',
            Info     => $Note,
            )
            : '';
        $Self->_Edit(
            Action => 'Add',
            %GetParam,
            %Errors,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminCompetenceLevel',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------
    # overview
    # ------------------------------------------------------------
    else {
        $Self->_Overview();

        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Info => Translatable('Level competence updated!') )
            if ( $Notification && $Notification eq 'Update' );

        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminCompetenceLevel',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

}

sub _Edit {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionOverview' );

    # get valid list
    my %ValidList        = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();
    my %ValidListReverse = reverse %ValidList;

    $Param{ValidOption} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        Class      => 'Modernize',
        SelectedID => $Param{ValidID} || $ValidListReverse{valid},
    );

    $LayoutObject->Block(
        Name => 'OverviewUpdate',
        Data => \%Param,
    );

    return 1;
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    my $LayoutObject          = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $CompetenceLevelObject = $Kernel::OM->Get('Kernel::System::CompetenceLevel');

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionAdd' );
    $LayoutObject->Block( Name => 'Filter' );

    my %List = $CompetenceLevelObject->CompetenceLevelList(
        Valid => 1,
    );

    $LayoutObject->Block(
        Name => 'OverviewResult',
        Data => \%Param,
    );

    # get valid list
    my %ValidList = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();
    for my $KeyList ( sort { $List{$a} cmp $List{$b} } keys %List ) {

        my %Data = $CompetenceLevelObject->CompetenceLevelGet( ID => $KeyList );
        $LayoutObject->Block(
            Name => 'OverviewResultRow',
            Data => {
                Valid => $ValidList{ $Data{ValidID} },
                %Data,
            },
        );
    }

    return 1;
}

1;
