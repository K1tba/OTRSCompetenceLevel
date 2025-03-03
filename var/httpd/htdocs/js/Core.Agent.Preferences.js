// --
// Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
// --
// This software comes with ABSOLUTELY NO WARRANTY. For details, see
// the enclosed file COPYING for license information (GPL). If you
// did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
// --

"use strict";

var Core = Core || {};
Core.Agent = Core.Agent || {};

/**
 * @namespace Core.Agent.Preferences
 * @memberof Core.Agent
 * @author OTRS AG
 * @description
 *      This namespace contains the special module functions for the AgentPreferences module.
 */
Core.Agent.Preferences = (function (TargetNS) {

    /**
     * @name Init
     * @memberof Core.Agent.Preferences
     * @function
     * @description
     *      This function initializes the module functionality.
     */
    TargetNS.Init = function () {
        Core.SystemConfiguration.InitConfigurationTree('AgentPreferences', null, 1);

        // make sure user has chosen at least one transport for mandatory notifications
        $('tr.Mandatory .NotificationEvent').closest('form').off().on('submit', function(Event) {
            $(this).find('tr.Mandatory').each(function() {
                var FoundEnabled = false;
                $(this).find('.NotificationEvent').each(function() {
                    if ($(this).prop('checked')) {
                        FoundEnabled = true;
                    }
                });

                // if there is not at least one transport enabled, omit the actions
                if (!FoundEnabled) {
                    alert(Core.Language.Translate("Sorry, but you can't disable all methods for notifications marked as mandatory."));
                    Event.preventDefault();
                    Event.stopPropagation();
                    return false;
                }
            });
        });

        $('.NotificationEvent').on('click', function(Event){
            var FoundEnabled = false,
                $TargetObj = $(this).parent().find('input[type=hidden]');

            // if the user is trying to disable this transport, go through all transport checkboxes
            // for this notification and check if at least one of them is checked
            if (!$(this).prop('checked') && $(this).closest('tr').hasClass('Mandatory')) {

                $(this).closest('tr.Mandatory').find('.NotificationEvent').each(function() {
                    if ($(this).prop('checked')) {
                        FoundEnabled = true;
                        return true;
                    }
                });

                // if there is not at least one transport enabled, omit the actions
                if (!FoundEnabled) {
                    alert(Core.Language.Translate("Sorry, but you can't disable all methods for this notification."));
                    Event.stopPropagation();
                    return false;
                }
            }

            if ($TargetObj.val() == 0){
                $TargetObj.val(1);
            }
            else{
                $TargetObj.val(0);
            }
        });

        $('#SaveAll').on('click', function() {
            $('button.Update:visible').trigger('click');
            return false;
        });

        // update classic preferences
        $('.PreferenceClassic button.Update').on('click', function() {

            var $FormObj = $(this).closest('form'),
                $WidgetObj = $(this).closest('.WidgetSimple'),
                $ButtonObj = $(this),
                Link = window.location.href.split('?')[1];

            Core.UI.WidgetOverlayShow($WidgetObj, 'Loading');

            Core.AJAX.FunctionCall(
                Core.Config.Get('Baselink') + 'ChallengeToken=' + Core.Config.Get('ChallengeToken'),
                Core.AJAX.SerializeForm($FormObj),
                function(Response) {

                    if (Response) {
                        if (Response.Priority === 'Error') {

                            // if there is already a message box, replace the content
                            if ($WidgetObj.find('.WidgetMessage').length) {
                                $WidgetObj.find('.WidgetMessage').text(Response.Message);
                            }
                            else {
                                $WidgetObj.find('.Content').before('<div class="WidgetMessage Top Error" style="display: none;"></div>');
                                $WidgetObj.find('.WidgetMessage').text(Response.Message);
                                $WidgetObj.find('.WidgetMessage').slideDown().delay(5000).slideUp(function() {
                                    $(this).remove();
                                });
                            }

                            Core.UI.WidgetOverlayHide($WidgetObj);
                        }
                        else {
                            Core.UI.WidgetOverlayHide($WidgetObj, true);

                            // if settings need a reload, show a notification
                            if (typeof Response.NeedsReload !== 'undefined' && parseInt(Response.NeedsReload, 10) > 0) {
                                Core.UI.ShowNotification(Core.Language.Translate('Please note that at least one of the settings you have changed requires a page reload. Click here to reload the current screen.'), 'Notice', Link);
                            }
                        }
                    }
                    else {

                        if ($WidgetObj.find('.WidgetMessage').length) {
                            $WidgetObj.find('.WidgetMessage').text(Response.Message);
                        }
                        else {
                            $WidgetObj.find('.Content').before('<div class="WidgetMessage Top Error" style="display: none;"></div>');
                            $WidgetObj.find('.WidgetMessage').text(Core.Language.Translate('An unknown error occurred. Please contact the administrator.'));
                            $WidgetObj.find('.WidgetMessage').slideDown().delay(5000).slideUp(function() {
                                $(this).remove();
                            });
                        }

                        Core.UI.WidgetOverlayHide($WidgetObj);
                    }

                    // Clear up password and two factor token fields.
                    $WidgetObj.find('input[type=password]').val('');
                    $WidgetObj.find('input[name=TwoFactorToken]').val('');

                    $ButtonObj.blur();
                }
            );

            return false;
        });

        TargetNS.InitSysConfig();

        Core.UI.Table.InitTableFilter($("#FilterSettings"), $(".SettingsList"));

        // --
        // OTRSCompetenceLevel
        // --

        //bind click function to add button
        $('.AddButton').on('click', function () {
        
            var $Table     = $(this).closest('table').attr('id'),
                $ValueID   = $('#DefaultValue' + $Table).val(),
                $ValueName = $('#DefaultValue' + $Table + ' option:selected').text(),
                $LevelID   = $('#DefaultCompetenceLevel' + $Table).val(),
                $LevelName = $('#DefaultCompetenceLevel' + $Table + ' option:selected').text();
            
            // if one of the required values is missing, we stop executing the function
            if ( !$ValueID || !$LevelID ) {
                return false;
            }

            if ( $ValueID === '0' || $LevelID === '0' ) {
               return false;
           }

            var NewRowHTML = Core.Template.Render('Agent/PreferencesCompetencie', {
                'ValueID'   : $ValueID,
                'LevelID'   : $LevelID,
                'ValueName' : $ValueName,
                'LevelName' : $LevelName
            });

            // add the generated HTML markup to the body of the table
            $('#' + $Table + ' tbody').append(NewRowHTML);

            // remove the selected element from the select element with the id 'DefaultValue' + table ID,
            // so that it is no longer available for selection.
            $('#DefaultValue' + $Table + ' option:selected').remove();

            $('#DefaultValue' + $Table).trigger('redraw.InputField');

            // return false to prevent a standard action and event occurrence
            return false;
        });

        //bind click function to remove button
        $('.DataTable').on('click', '.RemoveButton', function () {

            var $Table = $(this).closest('table').attr('id'),
                $Key   = $(this).attr('data-id'),
                $Value = $(this).attr('data-name');

            // if both values, the key and the name, are present, then we perform the action
            if ( $Key && $Value ) {

                // add the option back to the select element with the id 'DefaultValue' + table ID,
                // to return the deleted value to the selection list.
                $('#DefaultValue' + $Table).append('<option value="' + $Key + '">' + $Value + '</option>');

                $('#DefaultValue' + $Table).trigger('redraw.InputField');

                // remove the row in the table containing the delete button
                $(this).closest('tr').remove();
            }

            // return false to prevent a standard action and event occurrence
            return false;
        });
    };

    function SettingReset($Widget) {
        var SettingName = $Widget.find("input[name='SettingName']").val(),
            Data = "Action=AgentPreferences;Subaction=SettingReset;";

        Data += 'SettingName=' + encodeURIComponent(SettingName) + ';';

        // show loader
        Core.UI.WidgetOverlayShow($Widget, 'Loading');

        Core.AJAX.FunctionCall(
            Core.Config.Get('Baselink'),
            Data,
            function(Response) {

                if (Response.Error != null) {
                    alert(Response.Error);
                    // hide loader
                    Core.UI.WidgetOverlayHide($Widget);
                    return;
                }

                Core.SystemConfiguration.SettingRender(Response, $Widget);

                // hide loader
                Core.UI.WidgetOverlayHide($Widget);
            }
        );
    }

    TargetNS.InitSysConfig = function() {

        // save all
        $('#SaveAll').on('click', function() {
            $('.Setting').find('button.Update').trigger('click');
            return false;
        });

        // update sysconfig settings
        $('.WidgetSimple:not(.PreferenceClassic) button.Update').on('click', function() {
            Core.SystemConfiguration.Update($(this), 0, 0);
            return false;
        });

        // reset setting
        $('.WidgetSimple .ResetUserSetting a').on('click', function() {
            SettingReset($(this).closest(".WidgetSimple"));
            return false;
        });

        // Category update
        $('#Category').on('change', function() {
            var ParagraphHeight = $('#ConfigTree').height(),
                SelectedCategory = $(this).val();

            Core.Agent.PreferencesUpdate('UserSystemConfigurationCategory', SelectedCategory);

            $('#ConfigTree').html('<p class="Center"><i class="fa fa-spinner fa-spin"></i></p>');
            $('#ConfigTree > p').css('line-height', ParagraphHeight + 'px');
            Core.SystemConfiguration.InitConfigurationTree('AgentPreferences', SelectedCategory, 1);
        });
    }

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');

    return TargetNS;
}(Core.Agent.Preferences || {}));
