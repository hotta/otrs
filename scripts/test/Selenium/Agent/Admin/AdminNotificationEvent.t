# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

# get selenium object
my $Selenium = $Kernel::OM->Get('Kernel::System::UnitTest::Selenium');

$Selenium->RunTest(
    sub {

        # get helper object
        my $Helper = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');

        # do not check RichText
        $Helper->ConfigSettingChange(
            Valid => 1,
            Key   => 'Frontend::RichText',
            Value => 0
        );

        # create test user and login
        my $TestUserLogin = $Helper->TestUserCreate(
            Groups => ['admin'],
        ) || die "Did not get test user";

        $Selenium->Login(
            Type     => 'Agent',
            User     => $TestUserLogin,
            Password => $TestUserLogin,
        );

        # get script alias
        my $ScriptAlias = $Kernel::OM->Get('Kernel::Config')->Get('ScriptAlias');

        # navigate to AdminNotificationEvent screen
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AdminNotificationEvent");

        # check overview screen
        $Selenium->find_element( "table",             'css' );
        $Selenium->find_element( "table thead tr th", 'css' );
        $Selenium->find_element( "table tbody tr td", 'css' );

        # click "Add notification"
        $Selenium->find_element("//a[contains(\@href, \'Action=AdminNotificationEvent;Subaction=Add' )]")
            ->VerifiedClick();

        # check add NotificationEvent screen
        for my $ID (
            qw(Name Comment ValidID Events en_Subject en_Body)
            )
        {
            my $Element = $Selenium->find_element( "#$ID", 'css' );
            $Element->is_enabled();
            $Element->is_displayed();
        }

        # toggle Ticket filter widget
        $Selenium->find_element("//a[contains(\@aria-controls, \'Core_UI_AutogeneratedID_1')]")->VerifiedClick();

        # toggle Article filter (Only for ArticleCreate and ArticleSend event) widget
        $Selenium->find_element("//a[contains(\@aria-controls, \'Core_UI_AutogeneratedID_2')]")->VerifiedClick();

        # create test NotificationEvent
        my $NotifEventRandomID = "NotificationEvent" . $Helper->GetRandomID();
        my $NotifEventText     = "Selenium NotificationEvent test";
        $Selenium->find_element( "#Name",    'css' )->send_keys($NotifEventRandomID);
        $Selenium->find_element( "#Comment", 'css' )->send_keys($NotifEventText);
        $Selenium->execute_script("\$('#Events').val('ArticleCreate').trigger('redraw.InputField').trigger('change');");
        $Selenium->find_element( "#ArticleSubjectMatch", 'css' )->send_keys($NotifEventText);
        $Selenium->find_element( "#en_Subject",          'css' )->send_keys($NotifEventText);
        $Selenium->find_element( "#en_Body",             'css' )->send_keys($NotifEventText);
        $Selenium->find_element("//button[\@type='submit']")->VerifiedClick();

        # check if test NotificationEvent show on AdminNotificationEvent screen
        $Self->True(
            index( $Selenium->get_page_source(), $NotifEventRandomID ) > -1,
            "$NotifEventRandomID NotificaionEvent found on page",
        );

        # check test NotificationEvent values
        $Selenium->find_element( $NotifEventRandomID, 'link_text' )->VerifiedClick();

        $Self->Is(
            $Selenium->find_element( '#Name', 'css' )->get_value(),
            $NotifEventRandomID,
            "#Name stored value",
        );
        $Self->Is(
            $Selenium->find_element( '#Comment', 'css' )->get_value(),
            $NotifEventText,
            "#Comment stored value",
        );
        $Self->Is(
            $Selenium->find_element( '#en_Subject', 'css' )->get_value(),
            $NotifEventText,
            "#en_Subject stored value",
        );
        $Self->Is(
            $Selenium->find_element( '#en_Body', 'css' )->get_value(),
            $NotifEventText,
            "#en_Body stored value",
        );
        $Self->Is(
            $Selenium->find_element( '#ArticleSubjectMatch', 'css' )->get_value(),
            $NotifEventText,
            "#ArticleSubjectMatch stored value",
        );
        $Self->Is(
            $Selenium->find_element( '#ValidID', 'css' )->get_value(),
            1,
            "#ValidID stored value",
        );

        # edit test NotificationEvent and set it to invalid
        my $EditNotifEventText = "Selenium edited NotificationEvent test";

        # toggle Article filter (Only for ArticleCreate and ArticleSend event) widget
        $Selenium->find_element("//a[contains(\@aria-controls, \'Core_UI_AutogeneratedID_2')]")->VerifiedClick();

        $Selenium->find_element( "#Comment",             'css' )->clear();
        $Selenium->find_element( "#en_Body",             'css' )->clear();
        $Selenium->find_element( "#en_Body",             'css' )->send_keys($EditNotifEventText);
        $Selenium->find_element( "#en_Subject",          'css' )->clear();
        $Selenium->find_element( "#en_Subject",          'css' )->send_keys($EditNotifEventText);
        $Selenium->find_element( "#ArticleSubjectMatch", 'css' )->clear();
        $Selenium->find_element( "#ArticleBodyMatch",    'css' )->send_keys($EditNotifEventText);
        $Selenium->execute_script("\$('#ValidID').val('2').trigger('redraw.InputField').trigger('change');");
        $Selenium->find_element("//button[\@type='submit']")->VerifiedClick();

        # check edited NotifcationEvent values
        $Selenium->find_element( $NotifEventRandomID, 'link_text' )->VerifiedClick();

        $Self->Is(
            $Selenium->find_element( '#Comment', 'css' )->get_value(),
            "",
            "#Comment updated value",
        );
        $Self->Is(
            $Selenium->find_element( '#en_Body', 'css' )->get_value(),
            $EditNotifEventText,
            "#en_Body updated value",
        );
        $Self->Is(
            $Selenium->find_element( '#ArticleSubjectMatch', 'css' )->get_value(),
            "",
            "#ArticleSubjectMatch updated value",
        );
        $Self->Is(
            $Selenium->find_element( '#ArticleBodyMatch', 'css' )->get_value(),
            $EditNotifEventText,
            "#ArticleBodyMatch updated value",
        );
        $Self->Is(
            $Selenium->find_element( '#ValidID', 'css' )->get_value(),
            2,
            "#ValidID updated value",
        );

        # go back to AdminNotificationEvent overview screen
        $Selenium->VerifiedGet("${ScriptAlias}index.pl?Action=AdminNotificationEvent");

        # check class of invalid NotificationEvent in the overview table
        $Self->True(
            $Selenium->execute_script(
                "return \$('tr.Invalid td a:contains($NotifEventRandomID)').length"
            ),
            "There is a class 'Invalid' for test NotificationEvent",
        );

        # get NotificationEventID
        my %NotifEventID = $Kernel::OM->Get('Kernel::System::NotificationEvent')->NotificationGet(
            Name => $NotifEventRandomID
        );

        # click on delete icon
        my $CheckConfirmJS = <<"JAVASCRIPT";
(function () {
    window.confirm = function (message) {
        return true;
    };
}());
JAVASCRIPT
        $Selenium->execute_script($CheckConfirmJS);

        # delete test SLA with delete button
        $Selenium->find_element("//a[contains(\@href, \'Subaction=Delete;ID=$NotifEventID{ID}' )]")->VerifiedClick();

        # check if test NotificationEvent is deleted
        $Self->False(
            $Selenium->execute_script(
                "return \$('tr.Invalid td a:contains($NotifEventRandomID)').length"
            ),
            "Test NotificationEvent is deleted - $NotifEventRandomID",
        ) || die;

    }

);

1;
