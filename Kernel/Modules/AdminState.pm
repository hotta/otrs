# --
# Kernel/Modules/AdminState.pm - to add/update/delete system states 
# Copyright (C) 2002 Martin Edenhofer <martin+code@otrs.org>
# --
# $Id: AdminState.pm,v 1.4 2002-10-25 11:46:00 martin Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see 
# the enclosed file COPYING for license information (GPL). If you 
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

package Kernel::Modules::AdminState;

use strict;

use vars qw($VERSION);
$VERSION = '$Revision: 1.4 $';
$VERSION =~ s/^.*:\s(\d+\.\d+)\s.*$/$1/;

# --
sub new {
    my $Type = shift;
    my %Param = @_;

    # allocate new hash for object
    my $Self = {}; 
    bless ($Self, $Type);

    # get common opjects
    foreach (keys %Param) {
        $Self->{$_} = $Param{$_};
    }

    # check all needed objects
    foreach (qw(ParamObject DBObject PermissionObject LayoutObject ConfigObject LogObject)) {
        die "Got no $_" if (!$Self->{$_});
    }

    return $Self;
}
# --
sub Run {
    my $Self = shift;
    my %Param = @_;
    my $Output = '';
    my $NextScreen = 'AdminState';
    # --
    # permission check
    # --
    if (!$Self->{PermissionObject}->Section(UserID => $Self->{UserID}, Section => 'Admin')) {
        return $Self->{LayoutObject}->NoPermission();
    }
    # --
    # get data 2 form
    # --
    if ($Self->{Subaction} eq 'Change') {
        my $ID = $Self->{ParamObject}->GetParam(Param => 'ID') || '';
        $Output .= $Self->{LayoutObject}->Header(Title => 'System state change');
        $Output .= $Self->{LayoutObject}->AdminNavigationBar();
        my $SQL = "SELECT name, comment, valid_id " .
           " FROM " .
           " ticket_state " .
           " WHERE " .
           " id = $ID";
        $Self->{DBObject}->Prepare(SQL => $SQL);
        my @Data = $Self->{DBObject}->FetchrowArray();
        $Output .= $Self->{LayoutObject}->AdminStateForm(
                ID => $ID,
                Name => $Data[0],
                Comment => $Data[1], 
                ValidID => $Data[2],
            );
        $Output .= $Self->{LayoutObject}->Footer();
    }
    # --
    # update action
    # --
    elsif ($Self->{Subaction} eq 'ChangeAction') {
        my %GetParam;
        my @Params = ('ID', 'Name', 'Comment', 'ValidID');
        foreach (@Params) {
            $GetParam{$_} = $Self->{ParamObject}->GetParam(Param => $_) || '';
            $GetParam{$_} = $Self->{DBObject}->Quote($GetParam{$_}) || '';
            $GetParam{$_} = '' if (!exists $GetParam{$_});
        }
        my $SQL = "UPDATE ticket_state ".
          " SET ".
          " name = '$GetParam{Name}', ". 
          " comment = '$GetParam{Comment}', valid_id = $GetParam{ValidID}, " . 
          " change_time = current_timestamp, change_by = $Self->{UserID} " .
          " WHERE id = $GetParam{ID}";
        if ($Self->{DBObject}->Do(SQL => $SQL)) { 
            $Output .= $Self->{LayoutObject}->Redirect(OP => "Action=$NextScreen");
        }
        else {
        $Output .= $Self->{LayoutObject}->Header(Title => 'Error');
          $Output .= $Self->{LayoutObject}->Error(
                Message => 'DB Error!!',
                Comment => 'Please contact your admin');
          $Output .= $Self->{LayoutObject}->Footer();
        }
    }
    # --
    # add new queue
    # --
    elsif ($Self->{Subaction} eq 'AddAction') {
        my %GetParam;
        my @Params = ('Name', 'Comment', 'ValidID');
        foreach (@Params) {
            $GetParam{$_} = $Self->{ParamObject}->GetParam(Param => $_) || '';
            $GetParam{$_} = $Self->{DBObject}->Quote($GetParam{$_}) || '';
        }
        my $SQL = "INSERT INTO ticket_state (name, valid_id, comment, " .
		" create_time, create_by, change_time, change_by)" .
		" VALUES " .
		" ('$GetParam{Name}', $GetParam{ValidID}, " .
		" '$GetParam{Comment}', " .
		" current_timestamp, $Self->{UserID}, current_timestamp, $Self->{UserID})";
        if ($Self->{DBObject}->Do(SQL => $SQL)) {        
             $Output .= $Self->{LayoutObject}->Redirect(OP => "Action=$NextScreen");
        }
        else {
        $Output .= $Self->{LayoutObject}->Header(Title => 'Error');
        $Output .= $Self->{LayoutObject}->AdminNavigationBar();
        $Output .= $Self->{LayoutObject}->Error(
                Message => 'DB Error!!',
                Comment => 'Please contact your admin');
        $Output .= $Self->{LayoutObject}->Footer();
        }
    }
    # --
    # else ! print form 
    # --
    else {
        $Output .= $Self->{LayoutObject}->Header(Title => 'System state add');
        $Output .= $Self->{LayoutObject}->AdminNavigationBar();
        $Output .= $Self->{LayoutObject}->AdminStateForm();
        $Output .= $Self->{LayoutObject}->Footer();
    }
    return $Output;
}
# --

1;

