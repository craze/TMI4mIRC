/*
* TMI 4 mIRC
* Twitch Messaging Interface enhancements
*
* @author Geir André Halle
* @version 1.2.0
*/

; Some configuration options
alias -l tmiTrackFollowers { return $true }                    // Maintaining MODE +l can be $true or $false
alias -l tmiDownloadLogo { return $true }                      // Show channel logo in corner
alias -l tmiClientID { return qqzzeljmzs2x3q49k5lokkjcuckij7 } // API Client ID may be replaced with your own

on *:CONNECT:{
  if ($server == tmi.twitch.tv) { 
    .raw CAP REQ :twitch.tv/membership twitch.tv/commands twitch.tv/tags
    .parseline -qit :tmi.twitch.tv 005 $me PREFIX=(qaohv)~&@%+ NETWORK=Twitch
  }
}
on *:DISCONNECT:{ if ($server == tmi.twitch.tv) { unset %tmi4badges-* } }
raw CLEARMSG:*:{
  echo $color(kick) -t $1 * $msgtags(login).key got a message deleted ( $+ $2- $+ )
  haltdef
}
raw CLEARCHAT:*:{
  if (!$timer(clearchat- [ $+ [ $+($1,-,$2) ] ]) ) {
    var %tmiCCmsg, %tmiCCreason
    if (!$2) { var %tmiCCmsg = Chat was cleared by a moderator }
    elseif ($msgtags(ban-duration).key <= 10) { var %tmiCCmsg = $2 was purged by a moderator }
    elseif ($msgtags(ban-duration).key > 10) { var %tmiCCmsg = $2 has been timed out for $duration($msgtags(ban-duration).key) }
    else { var %tmiCCmsg = $2 has been permanently banned }
    var %tmiCCreason = $iif($msgtags(ban-reason).key,$+($chr(40),$replace($msgtags(ban-reason).key,\s,$chr(32)),$chr(41)),)
    echo $color(kick) -t $1 * %tmiCCmsg %tmiCCreason
  }
  if ($2) {
    .timerclearchat- [ $+ [ $+($1,-,$2) ] ] 1 5 return
  }
  haltdef
}
raw ROOMSTATE:*:{ 
  hadd -m $+(tmi.,$target) _id $msgtags(room-id).key
  if ($msgtags(emote-only).key || $msgtags(r9k).key || $msgtags(slow).key || $msgtags(subs-only).key || $msgtags(followers-only).key >= 0) {
    echo $color(info) -t $target * Channel restrictions: $iif($msgtags(emote-only).key,emote-only) $iif($msgtags(followers-only).key >= 0,followers-only( $+ $msgtags(followers-only).key $+ m)) $iif($msgtags(r9k).key,r9k) $iif($msgtags(slow).key,slow( $+ $msgtags(slow).key $+ s)) $iif($msgtags(subs-only).key,subscribers-only)
  }
  if ($msgtags(broadcaster-lang).key) {
    echo $color(info) -t $target * Broadcast lanugage: $msgtags(broadcaster-lang).key 
  }
  haltdef
}
raw USERSTATE:*:{ 
  hadd -m $+(tmi.,$me) color $msgtags(color).key
  hadd -m $+(tmi.,$me,.badges) $1 $msgtags(badges).key
  hadd -m $+(tmi.,$me) display-name $msgtags(display-name).key
  if ((%tmi4badges- [ $+ [ $target ] ] != $msgtags(badges).key) && (/ isin $msgtags(badges).key)) {
    set -e %tmi4badges- [ $+ [ $target ] ] $msgtags(badges).key
    echo $color(info) -t $target * Channel badges: $tmiparsebadges($msgtags(badges).key)
  }
  .timer 1 1 tmiSyncBadges $target $me $msgtags(badges).key
  haltdef 
}
raw HOSTTARGET:*:{ 
  if ($2 != -) {
    var %tmiHostmsg = hosting $+($chr(2),$2,$chr(2)) $iif($3 != -,for $+($chr(2),$3,$chr(2)) viewers,)
    echo $color(info) -t $1 * Now %tmiHostmsg
    if (($1 == $+($chr(35),$me)) && ($+($chr(35),$2) == $active)) { echo $color(info) -t $+($chr(35),$2) * You are now %tmiHostmsg } 
  }
  haltdef
}
raw USERNOTICE:*:{
  var %msg = $replace($msgtags(system-msg).key,\s,$chr(32),\n,$chr(32))  

  if ($gettok(%msg,2,32) == subscribed) { echo $color(info) -tm $1 * $tmiParseBadges($msgtags(badges).key) $tmiDisplayname($gettok(%msg,1,32)) $gettok(%msg,2-,32) }
  elseif ($gettok(%msg,2,32) == raiders) { echo $color(info) -tm $1 * $+($chr(2),$gettok(%msg,1,32),$chr(2)) $gettok(%msg,2-3,32) $tmiParseBadges($msgtags(badges).key) $tmiDisplayname($gettok(%msg,4,32)) $gettok(%msg,5-,32) }
  else { echo $color(info) -tm $1 * $tmiParseBadges($msgtags(badges).key) $replace($msgtags(system-msg).key,\s,$chr(32)) }

  if ($2) echo $color(info) -tm $1 * $tmiParseBadges($msgtags(badges).key) $tmiDisplayname($msgtags(display-name).key)) $+ : $2-
  haltdef
}
on *:INPUT:#:{ 
  if ($server == tmi.twitch.tv) {
    if (($left($1-,3) == /me) || ($left($1-,1) != /)) { 
      if ($tmiStyling) {
        var %tmiBadges = $tmiParseBadges($hget($+(tmi.,$me,.badges),$chan))
        if ($msgtags(badges).key != $hget($+(tmi.,$me,.badges),$chan)) { hadd -m $+(tmi.,$me,.badges) $chan $msgtags(badges).key }

        var %tmiNametag = %tmiBadges $chr(3) $+ $tmiHexcolor($hget($+(tmi.,$me),color)) $+ $hget($+(tmi.,$me),display-name) $+ $chr(3)
        .privmsg $chan $1-
        if ($1 == /me) { echo $color(action) -t $active * %tmiNametag $2- }
        else echo -t $active %tmiNametag $+ : $1-
        haltdef
      }
    }
  }
}
on ^*:NOTICE:*:#:{
  if (($server == tmi.twitch.tv) && ($nick == tmi.twitch.tv)) {
    if ($2 != hosting) { echo $color(info) -t $chan * $1- }
    haltdef
  }
}
on ^*:ACTION:*:#:{
  if ($server == tmi.twitch.tv) { 
    if ($nick ison $chan) { tmiRefresh $chan }
    tmiSyncBadges $chan $nick $msgtags(badges).key 
    if ($tmiStyling) {
      var %tmiChatter = * $tmiParseBadges($msgtags(badges).key) $tmiDisplayname($iif($msgtags(display-name).key,$msgtags(display-name).key,$nick)) $1- 

      echo $iif($highlight && ($regex($1-,/\b( $+ $me $+ $chr(124) $+ $anick $+ )\b/i)),$color(highlight),$color(action)) -tm $chan %tmiChatter
      haltdef
    }    
  }
}
on ^*:TEXT:*is now *hosting you*:?:{
  if (($server == tmi.twitch.tv) && ($nick == jtv)) { 
    var %tmiMychan = $chr(35) $+ $me
    echo $color(notice) -t %tmiMychan * $1-
    haltdef
  }
}
on ^*:TEXT:*:#:{
  if ($server == tmi.twitch.tv) {
    if ($nick ison $chan) { tmiRefresh $chan 
      if ($nick($chan,$nick($chan,$nick)) === $msgtags(display-name).key) { noop } 
      elseif ($nick($chan,$nick($chan,$nick)) == $msgtags(display-name).key) { .parseline -qit : $+ $nick NICK $msgtags(display-name).key }
    }
    tmiSyncBadges $chan $nick $msgtags(badges).key 
    if (($nick == twitchnotify) || ($nick == jtv)) {
      echo $color(info) -t $chan * $1-
      haltdef
    }
    elseif ($tmiStyling) {
      var %tmiChatter = $tmiParseBadges($msgtags(badges).key) $tmiDisplayname($iif($msgtags(display-name).key,$msgtags(display-name).key,$nick)) $+ : $iif($msgtags(msg-id).key == highlighted-message,$chr(22) $1- $chr(22),$1-) 

      echo $iif($highlight && ($regex($1-,/\b( $+ $me $+ $chr(124) $+ $anick $+ )\b/i)),$color(highlight)) -tm $chan %tmiChatter
      haltdef
    }
  }
}
on *:JOIN:#:{ if (($server == tmi.twitch.tv) && ($nick != $me)) { tmiRefresh $chan  } }
raw 366:*:{ if (($server == tmi.twitch.tv) && ($target == $me)) { tmiRefresh $2 } }

alias -l tmiecho { echo $color(info) -t $1- }
#tmiStyling on
alias -l tmiStyling return $true

alias -l tmiSyncBadges {
  var %tmichan = $1,%tminick = $2,%tmibadges = $3,%tmisync

  if (%tminick ison %tmichan) {
    var %tmimode = +
    if (((*broadcaster/* iswm %tmibadges)) && (~ !isin $nick(%tmichan,%tminick).pnick)) { var %tmimode = %tmimode $+ q }
    if (((*admin/* iswm %tmibadges) || (*staff/* iswm %tmibadges) || (*global_mod/* iswm %tmibadges)) && (& !isin $nick(%tmichan,%tminick).pnick)) { var %tmimode = %tmimode $+ a }    
    if ((*moderator/* iswm %tmibadges) && (%tminick !isop %tmichan)) { var %tmimode = %tmimode $+ o }
    if ((*subscriber/* iswm %tmibadges) && (%tminick !ishop %tmichan)) { var %tmimode = %tmimode $+ h }
    if ((*vip/* iswm %tmibadges) && (%tminick !isvoice %tmichan)) { var %tmimode = %tmimode $+ v }
    if ($count(%tmimode,q,a,o,h,v) > 0) { var %tmisync = $iif(($right(%tmichan,-1) ison %tmichan) && (%tminick != $me) && (%tminick != $right(%tmichan,-1)) && ($right(%tmichan,-1) !isop %tmichan),$replace(%tmimode,+,+o),%tmimode) }

    var %tmimode = -
    if ((*broadcaster/* !iswm %tmibadges) && (~ isin $nick(%tmichan,%tminick).pnick)) { var %tmimode = %tmimode $+ q }
    if (((*admin/* !iswm %tmibadges) && (*staff/* !iswm %tmibadges) && (*global_mod/* !iswm %tmibadges)) && (& isin $nick(%tmichan,%tminick).pnick)) { var %tmimode = %tmimode $+ a }    
    if (((*moderator/* !iswm %tmibadges) && (*broadcaster/* !iswm %tmibadges) && (*admin/* !iswm %tmibadges) && (*staff/* !iswm %tmibadges) && (*global_mod/* !iswm %tmibadges)) && (@ isin $nick(%tmichan,%tminick).pnick)) { var %tmimode = %tmimode $+ o }
    if ((*subscriber/* !iswm %tmibadges) && (%tminick ishop %tmichan)) { var %tmimode = %tmimode $+ h }
    if ((*vip/* !iswm %tmibadges) && (%tminick isvoice %tmichan)) { var %tmimode = %tmimode $+ v }
    if ($count(%tmimode,q,a,o,h,v) > 0) { var %tmisync = %tmisync $+ %tmimode }

    if ($count(%tmisync,q,a,o,h,v) > 0) { .parseline -qit : $+ $server MODE %tmichan %tmisync $iif(($right(%tmichan,-1) ison %tmichan) && (%tminick != $me) && (%tminick != $right(%tmichan,-1)) && ($right(%tmichan,-1) !isop %tmichan),$right(%tmichan,-1) $str(%tminick $chr(32), $calc($count(%tmisync,q,a,o,h,v) - 1)),$str(%tminick $chr(32), $count(%tmisync,q,a,o,h,v)))  }
  }
  return
}
alias -l tmiParseBadges {
  var %tmiBadgeReturn,%tmiI = 1
  while (%tmiI <= $numtok($1-,44)) {      
    %tmiBadgeReturn = %tmiBadgeReturn $+ $tmiBadge( $gettok($1-,%tmiI,44) )
    inc %tmiI
  }
  return %tmiBadgeReturn
}
alias tmiBadge {
  var %tmibadge
  if ($left($1,$pos($1,/)) == broadcaster/) { var %tmibadge = $chr(3) $+ 0,4 $+ 📹 $+ $chr(3) }
  elseif ($left($1,$pos($1,/)) == staff/) { var %tmibadge = $chr(3) $+ 0,2 $+ 🔧 $+ $chr(3) }
  elseif ($left($1,$pos($1,/)) == admin/) { var %tmibadge = $chr(3) $+ 0,7 $+ ⛊ $+ $chr(3) }
  elseif ($left($1,$pos($1,/)) == globalmod/) { var %tmibadge = $chr(3) $+ 0,3 $+ 🔨 $+ $chr(3) }
  elseif ($left($1,$pos($1,/)) == moderator/) { var %tmibadge = $chr(3) $+ 0,3 $+ 🗡 $+ $chr(3) }
  elseif ($left($1,$pos($1,/)) == turbo/) { var %tmibadge = $chr(3) $+ 0,6 $+ 🔋 $+ $chr(3) }
  elseif ($left($1,$pos($1,/)) == partner/) { var %tmibadge = $chr(3) $+ 0,6 $+ ✓ $+ $chr(3) }
  elseif ($left($1,$pos($1,/)) == premium/) { var %tmiBadge = $chr(3) $+ 0,12 $+ 👑 $+ $chr(3) }
  elseif ($left($1,$pos($1,/)) == vip/) { var %tmiBadge = $chr(3) $+ 0,13 $+ 💎 $+ $chr(3) }
  elseif ($left($1,$pos($1,/)) == glhf-pledge/) { var %tmiBadge = $chr(3) $+ 10 $+ ⌨️ $+ $chr(3) }
  elseif ($left($1,$pos($1,/)) == founder/) { var %tmiBadge = $chr(3) $+ 0,6 $+ 🥇 $+ $chr(3) }
  elseif ($left($1,$pos($1,/)) == sub-gifter/) { 
    var %tmiGiftNo = $gettok($1,2,47), %tmiSubC = 0
    if (%tmiGiftNo >= 1000) { var %tmiGiftC = 11,6 }
    elseif (%tmiGiftNo >= 500) { var %tmiGiftC = 8 }
    elseif (%tmiGiftNo >= 250) { var %tmiGiftC = 9 }
    elseif (%tmiGiftNo >= 100) { var %tmiGiftC = 7 }
    elseif (%tmiGiftNo >= 50) { var %tmiGiftC = 13 }
    elseif (%tmiGiftNo >= 25) { var %tmiGiftC = 4 }
    elseif (%tmiGiftNo >= 10) { var %tmiGiftC = 12 }
    elseif (%tmiGiftNo >= 5) { var %tmiGiftC = 10 }
    elseif (%tmiGiftNo >= 1) { var %tmiGiftC = 6 }    
    var %tmiBadge = $chr(3) $+ %tmiGiftC $+ 🎁 $+ $chr(3) 
  }
  elseif ($left($1,$pos($1,/)) == subscriber/) { 
    var %tmiSubM = $gettok($1,2,47), %tmiSubC = 0
    if ($gettok($1,2,47) >= 12) { var %tmiSubC = 8 }
    elseif ($gettok($1,2,47) >= 6) { var %tmiSubC = 15 }
    elseif ($gettok($1,2,47) >= 3) { var %tmiSubC = 7 }    
    var %tmibadge = $chr(3) $+ %tmiSubC $+ ,6 $+ ★ $+ $chr(3)
  }
  elseif ($left($1,$pos($1,/)) == bits-leader/) {
    var %tmiBitPos = $gettok($1,2,47)
    if (%tmiBitPos == 1) { var %tmibadge = $chr(3) $+ 1,8 $+ ① $+ $chr(3) }
    if (%tmiBitPos == 2) { var %tmibadge = $chr(3) $+ 1,15 $+ ② $+ $chr(3) }
    if (%tmiBitPos == 3) { var %tmibadge = $chr(3) $+ 1,7 $+ ③ $+ $chr(3) }
  }
  elseif ($left($1,$pos($1,/)) == bits/) {
    var %tmiBitsC = 1, %tmiBitsBG = 2, %tmiBitsS = ✷, %tmiBitsNo = $gettok($1,2,47)
    if (%tmiBitsNo < 100) { var %tmiBitsBG = 15, %tmiBitsS = ▲ }
    elseif (%tmiBitsNo < 1000) { var %tmiBitsBG = 13, %tmiBitsS = ♦ }
    elseif (%tmiBitsNo < 5000) { var %tmiBitsBG = 10, %tmiBitsS = ⬟ }
    elseif (%tmiBitsNo < 10000) { var %tmiBitsBG = 11, %tmiBitsS = ⬢ }
    elseif (%tmiBitsNo < 25000) { var %tmiBitsBG = 4, %tmiBitsS = 🟌 }
    elseif (%tmiBitsNo < 50000) { var %tmiBitsBG = 13, %tmiBitsS = 🟌 }
    elseif (%tmiBitsNo < 75000) { var %tmiBitsBG = 7, %tmiBitsS = 🟌 }
    elseif (%tmiBitsNo < 100000) { var %tmiBitsBG = 9, %tmiBitsS = 🟌 }
    elseif (%tmiBitsNo < 200000) { var %tmiBitsC = 5, %tmiBitsBG = 8, %tmiBitsS = ✷ }
    elseif (%tmiBitsNo < 300000) { var %tmiBitsC = 15 }
    elseif (%tmiBitsNo < 400000) { var %tmiBitsC = 13 }
    elseif (%tmiBitsNo < 500000) { var %tmiBitsC = 10 }
    elseif (%tmiBitsNo < 600000) { var %tmiBitsC = 11 }
    elseif (%tmiBitsNo < 700000) { var %tmiBitsC = 4 }
    elseif (%tmiBitsNo < 800000) { var %tmiBitsC = 13 }
    elseif (%tmiBitsNo < 900000) { var %tmiBitsC = 7 }
    elseif (%tmiBitsNo < 1000000) { var %tmiBitsC = 9 }
    else { var %tmiBitsBG = 8 }
    var %tmiBadge = $chr(3) $+ 1, $+ %tmiBitsBG $+ %tmiBitsS $+ $chr(3)   
  }
  elseif ($left($1,$pos($1,/)) == bits-charity/) { var %tmibadge = $chr(3) $+ 11 $+ ❄ $+ $chr(3) }
  return %tmibadge
}

alias -l tmiDisplayname {
  if ($regex($$1,\W)) { var %out = $+($chr(3),$tmiHexcolor($msgtags(color).key),$utfdecode($$1),$iif(($nick != $$1) && (. !isin $nick),$chr(40) $+ $nick $+ $chr(41),),$chr(3)) } 
  else { var %out = $+($chr(3),$tmiHexcolor($msgtags(color).key),$$1,$chr(3)) }
  return %out
}
alias -l tmiHexcolor {
  var %i = 0, %c, %d = 200000
  if ($1 == #2E8B57) { var %c = 10 }
  elseif ($1 == #5F9EA0) { var %c = 10 }
  elseif ($1 == #FF69B4) { var %c = 13 }
  elseif ($1 == #00FF7F) { var %c = 9 }
  else {
    tokenize 46 $regsubex($1,/#?([a-f\d]{2})/gi,$base(\1,16,10) .)
    while %i < 16 {
      tokenize 32 $1-3 $replace($rgb($color(%i)),$chr(44),$chr(32))
      if $calc(($1 -$4)^2 + ($2 -$5)^2 + ($3 -$6)^2) < %d {
        %c = %i
        %d = $v1
      }
      inc %i
    }
  }
  if (%c < 10) { %c = 0 $+ %c } ; Color must be double digits in case following text starts with a number
  return %c
}
#tmiStyling end
alias -l tmiStylingToggle {
  if ($group(#tmiStyling).status == on) { .disable #tmiStyling | tmiecho * Disabled Twitch styling }
  else { .enable #tmiStyling | tmiecho * Enabled Twitch styling }
}

alias tmiRefresh {
  ;Live status
  if ($sock(tmi4livestatus).name == tmi4livestatus) { return }
  if (($timer(tmi4livestatus.# $+ [ $1 ] ])) || ($timer(tmi4livestatus. $+ [ $1 ] ]))) { return }
  set -u0 %tmi4livestatus.chan $$1
  sockopen -e tmi4livestatus api.twitch.tv 443

  ;User list
  if ($sock(tmi4users).name == tmi4users) { return }
  if (($timer(tmiusers.# $+ [ $1 ] ])) || ($timer(tmiusers. $+ [ $1 ] ]))) { return }
  set %tmi4users.chan $$1
  sockopen -e tmi4users tmi.twitch.tv 443

  ;Topic / Logo
  if (($timer(tmi4topic.# $+ [ $1 ] ])) || ($timer(tmi4topic. $+ [ $1 ] ]))) { return }
  set %tmi4topic.chan $1
  set %tmi4topic.chanid $hget(tmi. $+ $1 ,_id)
  var %tmi4helix = https://api.twitch.tv/kraken/channels/ $+ %tmi4topic.chanid
  bset -t &tmi4urlhead 1 Client-ID: $tmiClientID $crlf Accept: application/vnd.twitchtv.v5+json $crlf Connection: close
  set -u0 %tmi4urlid $urlget(%tmi4helix,gb,&tmi4topic.data,tmi4helixdecode,&tmi4urlhead)

}
alias -l tmi4helixdecode {
  if (($timer(tmi4topic.# $+ [ %tmi4topic.chan ] ])) || ($timer(tmi4topic. $+ [ %tmi4topic.chan ] ]))) { return }
  var %id = $1
  var %tmi4json = $bvar(&tmi4topic.data,1,$bvar(&tmi4topic.data,0)).text

  if ("status":" isin $bvar(&tmi4topic.data,1,$bvar(&tmi4topic.data,0)).text) {
    var %tmi4jsonS = $calc( $pos(%tmi4json,"status":,1) + 10)
    var %tmi4jsonE = $calc( $pos( $mid(%tmi4json,$pos(%tmi4json,"status":,1)) ," $+ $chr(44) $+ ",1) - 11 )

    set %tmi4topic.status. [ $+ [ %tmi4topic.chan ] ] $tmiReplaceU( $mid(%tmi4json,%tmi4jsonS,%tmi4jsonE) )
    if ("game":null !isin $bvar(&tmi4topic.data,1,$bvar(&tmi4topic.data,0)).text) { 
      set %tmi4topic.game. [ $+ [ %tmi4topic.chan ] ] $tmiReplaceU( $mid( $matchtok($bvar(&tmi4topic.data,1,$bvar(&tmi4topic.data,0)).text,"game",1,44) ,9,-1) ) 
    }
    if (($tmiDownloadLogo) && ("logo":" isin $bvar(&tmi4topic.data,1,$bvar(&tmi4topic.data,0)).text)) { 
      set -u0 %tmi4helix.logo. [ $+ [ %tmi4topic.chan ] ] $tmiReplaceU( $mid( $matchtok($bvar(&tmi4topic.data,1,$bvar(&tmi4topic.data,0)).text,"logo",1,44) ,9,-1) ) 
      tmiPicDownload %tmi4topic.chan %tmi4helix.logo. [ $+ [ %tmi4topic.chan ] ]
    }
    ; Gathering extra data for populating channel modes
    set %tmi4topic.followers. [ $+ [ %tmi4topic.chan ] ] $tmiReplaceU( $gettok( $matchtok($bvar(&tmi4topic.data,1,$bvar(&tmi4topic.data,0)).text,"followers",1,44) ,2,58) ) 
    set %tmi4topic.modes. [ $+ [ %tmi4topic.chan ] ] $iif("mature":true isin $bvar(&tmi4topic.data,1,$bvar(&tmi4topic.data,0)).text,m,) $+ $iif("partner":true isin $bvar(&tmi4topic.data,1,$bvar(&tmi4topic.data,0)).text,p,)
  }

  tmi4topic %tmi4topic.chan
  unset %tmi4topic.*

}
alias -l tmiPicDownload { 
  var -l %chan = $1
  var -l %url = $2
  var -l %tmiPicFile = $+($scriptdirtmi4mirc\,%chan,.jpg)
  if ($calc( $ctime - $file(%tmiPicFile).mtime ) < 3600) return

  bset -t &tmiPic.Head 1 Accept: image/jpeg $crlf Connection: close
  set -u0 %tmi4helix.ID. [ $+ [ %chan ] ] $urlget(%url,gfr,%tmiPicFile,tmiPicUpdate,&tmiPic.Head)
}
alias -l tmiPicUpdate {
  var -l %chan = $left($gettok($urlget($1).target,-1,92),-4)
  background -p %chan $urlget($1).target
  unset %tmi4helix.*. [ $+ [ %chan ] ]
}
alias -l tmiReplaceU {
  return $strip($replace($$1-,\u0026,&,\u003c,<,\u003e,>,\",",\\,\,\n,))
}

menu channel {
  $iif($server == tmi.twitch.tv,Twitch ( $+ $right($chan,-1) $+ ))
  .Refresh chat:join $chan
  .$iif($me != $right($chan,-1),Host as $me):.privmsg $+($chr(35),$me) .host $right($chan,-1)
  .$iif($me == $right($chan,-1),Unhost):.privmsg $+($chr(35),$me) .unhost
  .-
  .List moderators:.privmsg $chan .mods
  .List VIPs:.privmsg $chan .vips
  .-
  ;.Config
  .$iif($group(#tmiStyling).status == on,Deactivate Twitch styling):tmiStylingToggle
  .$iif($group(#tmiStyling).status == off,Activate Twitch styling):tmiStylingToggle
}
menu nicklist {
  $iif(($server == tmi.twitch.tv) && (*moderator* iswm $hget($+(tmi.,$me,.badges),$chan) || ($right($chan,-1) == $me)),⚔ Twitch ( $+ $right($chan,-1) $+ ))
  .$iif($1 !isop $chan,✘ Purge $$1):.privmsg $chan .timeout $1 1
  .$iif($1 !isop $chan,🕘 Timeout $$1):.privmsg $chan .timeout $1
  .$iif($1 !isop $chan,🛇 Ban $$1):.privmsg $chan .ban $1
  .$iif($1 !isop $chan,✔ Unban $$1):.privmsg $chan .unban $1
  .-
  .Join $1 $+ 's chatroom:join $chr(35) $+ $$1
  .-
  .$iif($me = $right($chan,-1),🎥 Broadcaster options)
  ..$iif($$1 !isop $chan,Mod $$1):.privmsg $chan .mod $1
  ..$iif($$1 isop $chan,Unmod $$1):.privmsg $chan .unmod $1
}
menu status {
  $iif(($server == tmi.twitch.tv) && (https?//*.twitch.tv/* iswm $url),Twitch)
  .Join $gettok($gettok($url,3,47),1,63) $+ 's chatroom:.join # $+ $gettok($gettok($url,3,47),1,63)
}


;;; Number of followers as channel limit (+l)
alias -l tmi4users {
  if ($1 ischan) { var %c = $1 }
  else { return }

  var %i = 1
  while (%i <= $numtok(%tmi4users. [ $+ [ %c ] $+ -q  ],32)) {
    var %n = $gettok(%tmi4users. [ $+ [ %c ] $+ -q  ],%i,32)
    if ((%n ison %c) && (~ !isin $nick(%c,%n).pnick)) var %q = $addtok(%q,%n,32)
    inc %i
  }
  var %i = 1
  while (%i <= $numtok(%tmi4users. [ $+ [ %c ] $+ -a  ],32)) {
    var %n = $gettok(%tmi4users. [ $+ [ %c ] $+ -a  ],%i,32)
    if ((%n ison %c) && (& !isin $nick(%c,%n).pnick)) var %a = $addtok(%a,%n,32)
    inc %i
  }
  var %i = 1
  while (%i <= $numtok(%tmi4users. [ $+ [ %c ] $+ -o  ],32)) {
    var %n = $gettok(%tmi4users. [ $+ [ %c ] $+ -o  ],%i,32)
    if ((%n ison %c) && (%n !isop %c)) var %o = $addtok(%o,%n,32)
    inc %i
  }
  var %i = 1
  while (%i <= $numtok(%tmi4users. [ $+ [ %c ] $+ -v  ],32)) {
    var %n = $gettok(%tmi4users. [ $+ [ %c ] $+ -v  ],%i,32)
    if ((%n ison %c) && (+ !isin $nick(%c,%n).pnick)) var %v = $addtok(%v,%n,32)
    inc %i
  }
  var %i = 1
  while (%i <= $numtok(%tmi4users. [ $+ [ %c ] $+ -r  ],32)) {
    var %n = $gettok(%tmi4users. [ $+ [ %c ] $+ -r  ],%i,32)
    if (%n ison %c) { 
      var %tmi4users.regular
      if (~ isin $nick(%c,%n).pnick) { var %tmi4users.regular = %tmi4users.regular $+ q }
      if (& isin $nick(%c,%n).pnick) { var %tmi4users.regular = %tmi4users.regular $+ a }
      if (@ isin $nick(%c,%n).pnick) { var %tmi4users.regular = %tmi4users.regular $+ o }
      if (+ isin $nick(%c,%n).pnick) { var %tmi4users.regular = %tmi4users.regular $+ v }
      if (%tmi4users.regular != $null) { .parseline -qit : $+ $server MODE %c - $+ %tmi4users.regular $str(%n,$numtok(%tmi4users.regular,32) $+ $chr(32)) }
    }
    inc %i
  }

  if ((%q != $null) || (%a != $null) || (%o != $null) || (%v != $null)) { .parseline -qit : $+ $server MODE %c + $+ $str(q,$numtok(%q,32)) $+ $str(a,$numtok(%a,32)) $+ $str(o,$numtok(%o,32)) $+ $str(v,$numtok(%v,32)) %q %a %o %v }
  if (($server == tmi.twitch.tv) && (%c ischan)) { .timer [ $+ tmiusers. $+ [ %c ] ] 1 90 return }
}
on *:sockopen:tmi4users:{
  if ($sockerr > 0) return

  if ($left(%tmi4users.chan,1) == $chr(35)) { var %tmi4users.uri = /group/user/ $+ $right(%tmi4users.chan,-1) $+ /chatters }
  else { var %tmi4users.uri = /group/user/ $+ %tmi4users.chan $+ /chatters }

  sockwrite -tn tmi4users GET %tmi4users.uri HTTP/1.1
  sockwrite -tn tmi4users Host: tmi.twitch.tv
  sockwrite -tn tmi4users Connection: close
  sockwrite -tn tmi4users $crlf
}
on *:sockread:tmi4users:{
  if ($sockerr > 0) return

  sockread %tmi4users.data

  if ("broadcaster": isin %tmi4users.data) { set %tmi4users.next q }
  if ("vips": isin %tmi4users.data) { set %tmi4users.next v }
  if ("moderators": isin %tmi4users.data) { set %tmi4users.next o }
  if (("staff": isin %tmi4users.data) || ("admins": isin %tmi4users.data) || ("global_mods": isin %tmi4users.data)) { set %tmi4users.next a }
  if ("viewers": isin %tmi4users.data) { set %tmi4users.next r }
  if ($chr(93) isin %tmi4users.data) { unset %tmi4users.next }

  if ((%tmi4users.next) && ($chr(91) !isin %tmi4users.data)) { 
    var %tmi4pos = $calc($pos(%tmi4users.data,",1) + 1)
    var %tmi4len = $calc($pos(%tmi4users.data,",2) - %tmi4pos)
    var %tmi4usr = $mid(%tmi4users.data, %tmi4pos , %tmi4len )
    if (%tmi4usr ison %tmi4users.chan) {
      if (%tmi4users.next isin qaohv) { set %tmi4users. [ $+ [ %tmi4users.chan ] $+ - $+ [ %tmi4users.next ] ] $addtok(%tmi4users. [ $+ [ %tmi4users.chan ] $+ - $+ [ %tmi4users.next ] ],%tmi4usr,32) }
      if ((%tmi4usr ison %tmi4users.chan) && (%tmi4usr !isreg %tmi4users.chan) && (%tmi4users.next == r)) { set %tmi4users. [ $+ [ %tmi4users.chan ] $+ - $+ [ %tmi4users.next ] ] $addtok(%tmi4users. [ $+ [ %tmi4users.chan ] $+ - $+ [ %tmi4users.next ] ],%tmi4usr,32) }
    }
  }

  if ($sockbr == 0) return
}


;;; Title and game as topic
alias -l tmi4topic {
  if ($1 ischan) { 
    var %c = $1
    goto settopic 
  } 
  elseif ($active ischan) { 
    var %c = $active
    goto settopic
  }
  return
  :settopic
  if (%tmi4topic.status. [ $+ [ %c ] ] ) {
    var %newtopic = $chr(3) $+ $iif($len($color(info)) == 1,0,) $+ $color(info) $+ %tmi4topic.status. [ $+ [ %c ] ] $+ $chr(3) $iif(%tmi4topic.game. [ $+ [ %c ] ],$chr(40) $+ $chr(3) $+ $iif($len($color(other)) == 1,0,) $+ $color(other) $+ %tmi4topic.game. [ $+ [ %c ] ] $+ $chr(3) $+ $chr(41),)
    if ($chan(%c).topic != %newtopic) { .parseline -qit : $+ $server TOPIC %c : $+ %newtopic }
  }
  ;Additional info as channel modes
  var %cmode $iif(%tmi4topic.modes. [ $+ [ %c ] ] isin $chan(%c).mode,,%tmi4topic.modes. [ $+ [ %c ] ])
  if (($tmiTrackFollowers) && (%tmi4topic.followers. [ $+ [ %c ] ] != $chan(%c).limit)) { var %cmode = %cmode $+ l %tmi4topic.followers. [ $+ [ %c ] ] }
  if ($count(%cmode,l,m,p)) { .parseline -qit : $+ $server MODE %c + $+ %cmode }
  .timer [ $+ tmitopic. $+ [ %c ] ] 1 120 return
}
on *:sockclose:tmi4users:{ 
  tmi4users %tmi4users.chan
  unset %tmi4users.*
}

;;; Stream status (live/rerun/offline) as channel key (+k)
alias -l tmi4livestatus {
  if ($1 ischan) { 
    var %c = $1
    goto setstatus
  } 
  elseif ($active ischan) { 
    var %c = $active
    goto setstatus
  }
  return

  :setstatus
  if (%tmi4livestatus. [ $+ [ %c ] ] ) {
    var %newstatus = %tmi4livestatus. [ $+ [ %c ] ] 
    if (($len($chan(%c).key) == 0) && ($chan(%c).key != %newstatus)) { .parseline -qit : $+ $server MODE %c :+k %newstatus }
    elseif ($chan(%c).key != %newstatus) { .parseline -qit : $+ $server MODE %c :-k+k $chan(%c).key %newstatus }
  }
  ;Additional info as channel modes
  ;var %cmode $iif(%tmi4livestatus.modes. [ $+ [ %c ] ] isin $chan(%c).mode,,%tmi4livestatus.modes. [ $+ [ %c ] ])
  ;if (($tmiTrackFollowers) && (%tmi4livestatus.followers. [ $+ [ %c ] ] != $chan(%c).limit)) { var %cmode = %cmode $+ l %tmi4livestatus.followers. [ $+ [ %c ] ] }
  ;if ($count(%cmode,l,m,p)) { .parseline -qit : $+ $server MODE %c + $+ %cmode }
  .timer [ $+ tmistatus. $+ [ %c ] ] 1 120 return
}
on *:sockopen:tmi4livestatus:{
  if ($sockerr > 0) return

  ;if ($left(%tmi4livestatus.chan,1) == $chr(35)) { var %tmi4livestatus.uri = /kraken/streams/ $+ $right(%tmi4livestatus.chan,-1) $+ ?client_id= $+ $tmiClientID }
  ;else { var %tmi4livestatus.uri = /kraken/streams/ $+ %tmi4livestatus.chan $+ ?client_id= $+ $tmiClientID }
  if ($left(%tmi4livestatus.chan,1) == $chr(35)) { var %tmi4livestatus.uri = /helix/streams?user_login= $+ $right(%tmi4livestatus.chan,-1) }
  else { var %tmi4livestatus.uri = /helix/streams?user_login= $+ %tmi4livestatus.chan }

  sockwrite -tn tmi4livestatus GET %tmi4livestatus.uri HTTP/1.1
  sockwrite -tn tmi4livestatus Client-ID: $tmiClientID
  sockwrite -tn tmi4livestatus Host: api.twitch.tv
  sockwrite -tn tmi4livestatus Connection: close
  sockwrite -tn tmi4livestatus $crlf
}
on *:sockread:tmi4livestatus:{
  if ($sockerr > 0) return
  sockread &tmi4livestatus.data

  if ("type": isin $bvar(&tmi4livestatus.data,1,$bvar(&tmi4livestatus.data,0)).text) {
    set -e %tmi4livestatus. [ $+ [ %tmi4livestatus.chan ] ] $upper( $mid( $matchtok($bvar(&tmi4livestatus.data,1,$bvar(&tmi4livestatus.data,0)).text,"type":,1,44) ,9,-1) )
    return
  }
  elseif ("data":[] isin $bvar(&tmi4livestatus.data,1,$bvar(&tmi4livestatus.data,0)).text) { set %tmi4livestatus. [ $+ [ %tmi4livestatus.chan ] ] OFFLINE }

  if ($sockbr == 0) return
}
on *:sockclose:tmi4livestatus:{ 
  tmi4livestatus %tmi4livestatus.chan
  ;unset %tmi4livestatus.*
}
