# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Language::ru_OTRSCompetenceLevel;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Template: AdminCompetenceLevel
    $Self->{Translation}->{'Competence Level Management'} = 'Управление уровнем компетенции';
    $Self->{Translation}->{'Add Competence Level'} = 'Добавить уровень компетенции';
    $Self->{Translation}->{'Edit Competence Level'} = 'Редактировать уровень компетенции';
    $Self->{Translation}->{'Filter for competence levels'} = 'Фильтр для уровней компетенции';
#    $Self->{Translation}->{''} = '';

    # Perl Module: Kernel/Modules/AdminCompetenceLevel.pm
    $Self->{Translation}->{'Level competence added!'} = 'Уровень компетенции добавлен!';
    $Self->{Translation}->{'Level competence updated!'} = 'Уровень компетенции обновлен!';
#    $Self->{Translation}->{''} = '';

    # SysConfig
    $Self->{Translation}->{'Competences'} = 'Компетенции';
    $Self->{Translation}->{'Competence level'} = 'Уровень компетенции';
    $Self->{Translation}->{'Competence Level'} = 'Уровень Компетенций';
    $Self->{Translation}->{'Competence levels'} = 'Уровни компетенции';
    $Self->{Translation}->{'Create and manage competence levels.'} = 'Создание и управление уровнями компетенции.';
    $Self->{Translation}->{'To edit they own competence levels.'}
        = 'Редактировать свои собственные уровни компетенции.';
    $Self->{Translation}->{'Group competence(s)'} = 'Компетенции по группам';
    $Self->{Translation}->{'Define competences for «Groups».'} =
        'Определите компетенции для «Групп»';
    $Self->{Translation}->{'Role competence(s)'} = 'Компетенции по группам';
    $Self->{Translation}->{'Define competences for «Roles».'} =
        'Определите компетенции для «Ролей».';
    $Self->{Translation}->{'Priority competence(s)'} = 'Компетенции по приоритетам';
    $Self->{Translation}->{'Define competences for «Prioritys».'}
        = 'Определите компетенции для «Приоритетов».';
    $Self->{Translation}->{'Queue competence(s)'} = 'Компетенции по очередям';
    $Self->{Translation}->{'Define competences for «Queues».'}
        = 'Определите компетенции для «Очередей».';
    $Self->{Translation}->{'Type competence(s)'} = 'Компетенции по типам';
    $Self->{Translation}->{'Define competences for «Types».'}
        = 'Определите компетенции для «Типов».';
    $Self->{Translation}->{'Service competence(s)'} = 'Компетенции по типам';
    $Self->{Translation}->{'Define competences for «Services».'}
        = 'Определите компетенции для «Сервисов».';
    $Self->{Translation}->{'SLA competence(s)'} = 'Компетенции по SLA';
    $Self->{Translation}->{'Define competences for «SLAs».'}
        = 'Определите компетенции для «SLAs».';
#    $Self->{Translation}->{''} = '';

    push @{ $Self->{JavaScriptStrings} // [] }, (
    );

}

1;
