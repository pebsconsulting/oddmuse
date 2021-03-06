# Copyright (C) 2010–2015  Alex Schroeder <alex@gnu.org>
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.

use strict;
use v5.10;

AddModuleDescription('gravatar.pl', 'Gravatar');

use Digest::MD5 qw(md5_hex);

our ($q, $bol, %CookieParameters, $FullUrlPattern, @MyRules, @MyInitVariables, @MyFormChanges);

# Same as in mail.pl
$CookieParameters{mail} = '';

my $gravatar_regexp = "\\[\\[gravatar:(?:$FullUrlPattern )?([^\n:]+):([0-9a-f]+)\\]\\]";

push(@MyRules, \&GravatarRule);

sub GravatarRule {
  if ($bol && m!\G$gravatar_regexp!cg) {
    my $url = $1;
    my $gravatar = "https://secure.gravatar.com/avatar/$3";
    my $name = FreeToNormal($2);
    $url = ScriptUrl($name) unless $url;
    return $q->span({-class=>"portrait gravatar"},
		    $q->a({-href=>$url,
			   -class=>'newauthor'},
			  $q->img({-src=>$gravatar,
				   -class=>'portrait',
				   -alt=>''})),
		    $q->br(),
		    GetPageLink($name));
  }
  return;
}

sub GravatarFormAddition {
  my ($html, $type) = @_;

  # gravatars only make sense for comments
  return $html unless $type eq 'comment';

  my $addition = $q->span({-class=>'mail'},
			  $q->label({-for=>'mail'}, T('Email:') . ' ')
			  . ' ' . $q->textfield(-name=>'mail', -id=>'mail',
						-default=>GetParam('mail', '')));
  $html =~ s!(name="homepage".*?)</p>!$1 $addition</p>!i;
  return $html;
}

push(@MyInitVariables, \&AddGravatar);

sub AddGravatar {

  # the implementation in mail.pl takes precedence!
  if (not grep { $_ == \&MailFormAddition } @MyFormChanges) {
    push(@MyFormChanges, \&GravatarFormAddition);
  }

  my $aftertext = UnquoteHtml(GetParam('aftertext'));
  my $mail = GetParam('mail');
  $mail =~ s/^[ \t]+//;
  $mail =~ s/[ \t]+$//;
  my $gravatar = md5_hex(lc($mail));
  my $username = GetParam('username');
  my $homepage = GetParam('homepage');
  $homepage = 'http://' . $homepage
    if $homepage and $homepage !~ m!^https?://!i;
  $homepage .= ' ' if $homepage;
  if ($aftertext && $mail && $aftertext !~ /^\[\[gravatar:/) {
    SetParam('aftertext',
	     "[[gravatar:$homepage $username:$gravatar]]\n$aftertext");
  }
}

*GravatarOldGetSummary = \&GetSummary;
*GetSummary = \&GravatarNewGetSummary;

sub GravatarNewGetSummary {
  my $summary = GravatarOldGetSummary(@_);
  $summary =~ s/^$gravatar_regexp *//;
  return $summary;
}
