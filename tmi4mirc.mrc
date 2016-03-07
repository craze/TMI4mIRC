/*
* TMI 4 mIRC
* Twitch Messaging Interface enhancements
*
* @author Geir André Halle
* @version 1.0.60307
*/
on *:CONNECT:{
  if ($server == tmi.twitch.tv) { 
    .raw CAP REQ :twitch.tv/membership twitch.tv/commands twitch.tv/tags
  }
}
raw CLEARCHAT:*:{
  if (!$timer(clearchat- [ $+ [ $+($1,-,$2) ] ]) ) {
    echo $color(kick) -t $1 * $iif($2,$2 was purged,Chat was cleared) by a moderator
  }
  if ($2) {
    .timerclearchat- [ $+ [ $+($1,-,$2) ] ] 1 5 return
  }
  haltdef
}
raw ROOMSTATE:*:{ 
  if ($msgtags(r9k).key || $msgtags(slow).key || $msgtags(subs-only).key) {
    echo $color(info) -t $target * Channel restrictions: $iif($msgtags(r9k).key,r9k) $iif($msgtags(slow).key,slow) $iif($msgtags(subs-only).key,subscribers-only)
  }
  if ($msgtags(broadcaster-lang).key) {
    echo $color(info) -t $target * Broadcast lanugage: $msgtags(broadcaster-lang).key 
  }
  haltdef
}
raw USERSTATE:*:{ 
  hadd -m $+(tmi.,$me) color $msgtags(color).key
  hadd -m $+(tmi.,$me) display-name $msgtags(display-name).key
  if ($msgtags(user-type).key != $hget($+(tmi.user-type.,$1),$me)) hadd -m $+(tmi.user-type.,$1) $me $msgtags(user-type).key
  if ($msgtags(turbo).key != $hget($+(tmi.turbo),$me)) hadd -m $+(tmi.turbo) $me
  if ($msgtags(subscriber).key) != $hget($+(tmi.subscriber.,$1),$me) hadd -m $+(tmi.subscriber.,$1) $me $msgtags(subscriber).key
  if ((!$timer(tmi4input- [ $+ [ $target ] ]) ) && ($msgtags(user-type).key || $msgtags(subscriber).key || $msgtags(turbo).key)) {
    echo $color(info) -t $target * Channel privileges: $iif($msgtags(user-type).key,$tmiBadge($msgtags(user-type).key)) $iif($right($target,-1) == $me,$tmibadge(broadcaster)) $iif($msgtags(subscriber).key,$tmibadge(subscriber)) $iif($msgtags(turbo).key,$tmibadge(turbo))
  }
  haltdef 
}
raw HOSTTARGET:*:{ 
  if ($2 != -) {
    var %tmiHostmsg = * Now hosting $+($chr(2),$2,$chr(2)) $iif($3 != -,for $+($chr(2),$3,$chr(2)) viewers,)
    echo $color(info) -t $1 %tmiHostmsg
    if (($1 == $+($chr(35),$me)) && ($+($chr(35),$2) == $active)) { echo $color(info) -t $+($chr(35),$2) %tmiHostmsg } 
  }
  haltdef
}
on 1:INPUT:#:{ 
  if ($server == tmi.twitch.tv) {
    if (($left($1-,3) == /me) || ($left($1-,1) != /)) { .timertmi4input- [ $+ [ $chan ] ] 1 2 return 
      if ($tmiStyling) {
        var %tmiBadges = $iif($right($chan,-1) == $me,$tmiBadge(broadcaster),$iif($hget($+(tmi.user-type.,$chan),$me),$tmiBadge($hget($+(tmi.user-type.,$chan),$me)))) $+ $iif($hfind(tmi.turbo,$me),$tmiBadge(turbo)) $+ $iif($hget($+(tmi.subscriber.,$chan),$me) == 1,$tmiBadge(subscriber))
        var %tmiNametag = %tmiBadges $chr(3) $+ $tmiHexcolor($hget($+(tmi.,$me),color)) $+ $hget($+(tmi.,$me),display-name) $+ $chr(3)
        privmsg $chan $1-
        if ($1 == /me) { echo $color(action) -t $active * %tmiNametag $2- }
        else echo -t $active %tmiNametag $+ : $1-
        haltdef
      }
    }
  }
}
on ^1:NOTICE:*:#:{
  if (($server == tmi.twitch.tv) && ($nick == tmi.twitch.tv)) {
    if ($2 != hosting) { echo $color(info) -t $chan * $1- }
    haltdef
  }
}
on ^1:ACTION:*:#:{
  if ($server == tmi.twitch.tv) { 
    if ($tmiStyling) {
      if ($msgtags(user-type).key != $hget($+(tmi.user-type.,$chan),$nick)) { hadd -m $+(tmi.user-type.,$chan) $nick $msgtags(user-type).key }
      if ($msgtags(turbo).key != $hget($+(tmi.turbo),$nick)) hadd -m $+(tmi.turbo) $nick
      if ($msgtags(subscriber).key != $hget($+(tmi.turbo),$nick)) { hadd -m $+(tmi.subscriber.,$chan) $nick $msgtags(subscriber).key }

      var %tmiChatter = $iif($right($chan,-1) == $nick,$tmiBadge(broadcaster),$iif($msgtags(user-type).key,$tmiBadge($msgtags(user-type).key)))
      var %tmiChatter = %tmiChatter $+ $iif($msgtags(turbo).key == 1,$tmiBadge(turbo))
      var %tmiChatter = %tmiChatter $+ $iif($msgtags(subscriber).key == 1,$tmiBadge(subscriber))
      var %tmiChatter = * %tmiChatter $tmiDisplayname($msgtags(display-name).key) $1- 
      echo $color(action) -t $chan %tmiChatter
      haltdef
    }    
  }
}
on ^1:TEXT:*:#:{
  if ($server == tmi.twitch.tv) { 
    if (($nick == twitchnotify) || ($nick == jtv)) {
      if (!$istok($1-,to,32)) { echo $color(info) -t $chan * $1- }
      haltdef
    }
    elseif ($tmiStyling) {
      if ($msgtags(user-type).key != $hget($+(tmi.user-type.,$chan),$nick)) { hadd -m $+(tmi.user-type.,$chan) $nick $msgtags(user-type).key }
      if ($msgtags(turbo).key != $hget($+(tmi.turbo),$nick)) hadd -m $+(tmi.turbo) $nick
      if ($msgtags(subscriber).key != $hget($+(tmi.turbo),$nick)) { hadd -m $+(tmi.subscriber.,$chan) $nick $msgtags(subscriber).key }

      var %tmiChatter = $iif($right($chan,-1) == $nick,$tmiBadge(broadcaster),$iif($msgtags(user-type).key,$tmiBadge($msgtags(user-type).key)))
      var %tmiChatter = %tmiChatter $+ $iif($msgtags(turbo).key == 1,$tmiBadge(turbo))
      var %tmiChatter = %tmiChatter $+ $iif($msgtags(subscriber).key == 1,$tmiBadge(subscriber))
      var %tmiChatter = %tmiChatter $tmiDisplayname($msgtags(display-name).key) $+ : $1- 
      echo -t $chan %tmiChatter
      haltdef
    }
  }
}

alias -l tmiecho { echo $color(info) -t $1- }
#tmiStyling on
alias -l tmiStyling return $true

alias tmiBadge {
  var %tmibadge
  if ($1 == broadcaster) { var %tmibadge = $chr(3) $+ 0,4 🎥 $chr(3) }
  elseif ($1 == staff) { var %tmibadge = $chr(3) $+ 0,2 🔧 $chr(3) }
  elseif ($1 == admin) { var %tmibadge = $chr(3) $+ 0,7 ⛊ $chr(3) }
  elseif ($1 == globalmod) { var %tmibadge = $chr(3) $+ 0,3 🔨 $chr(3) }
  elseif ($1 == mod) { var %tmibadge = $chr(3) $+ 0,3 ⚔ $chr(3) }
  elseif ($1 == turbo) { var %tmibadge = $chr(3) $+ 0,6 🔋 $chr(3) }
  elseif ($1 == subscriber) { var %tmibadge = $chr(22) ★ $chr(22) }
  return %tmibadge
}

alias -l tmiDisplayname return $+($chr(3),$tmiHexcolor($msgtags(color).key),$replace($$1,\s,$chr(32)),$chr(3))
alias -l tmiHexcolor {
  var %i = 0, %c, %d = 200000
  if ($1 == #2E8B57) { var %c = 10 }
  elseif ($1 == #5F9EA0) { var %c = 10 }
  elseif ($1 == #FF69B4) { var %c = 13 }
  elseif ($1 == #00FF7F) { var %c = 09 }
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
  return %c
}
#tmiStyling end
alias -l tmiStylingToggle {
  if ($group(#tmiStyling).status == on) { .disable #tmiStyling | tmiecho * Disabled Twitch styling }
  else { .enable #tmiStyling | tmiecho * Enabled Twitch styling }
}

menu channel {
  $iif($server == tmi.twitch.tv,Twitch ( $+ $right($chan,-1) $+ ))
  .Refresh chat:join $chan
  .List moderators:.privmsg $chan .mods
  .$iif($me != $right($chan,-1),Host as $me):privmsg $+($chr(35),$me) .host $right($chan,-1)
  .$iif($me == $right($chan,-1),Unhost):privmsg $+($chr(35),$me) .unhost
  .-
  ;.Config
  .$iif($group(#tmiStyling).status == on,Deactivate Twitch styling):tmiStylingToggle
  .$iif($group(#tmiStyling).status == off,Activate Twitch styling):tmiStylingToggle
}
menu nicklist {
  $iif(($server == tmi.twitch.tv) && ($hget($+(tmi.user-type.,$chan),$me) || ($right($chan,-1) == $me)),⚔ Twitch ( $+ $right($chan,-1) $+ ))
  .$iif(!$hget($+(tmi.user-type.,$chan),$1),✘ Purge $$1):.privmsg $chan .timeout $1 1
  .$iif(!$hget($+(tmi.user-type.,$chan),$1),🕘 Timeout $$1):.privmsg $chan .timeout $1
  .$iif(!$hget($+(tmi.user-type.,$chan),$1),🛇 Ban $$1):.privmsg $chan .ban $1
  .$iif(!$hget($+(tmi.user-type.,$chan),$1),✔ Unban $$1):.privmsg $chan .unban $1
  .-
  .Join $1 $+ 's chatroom:join $chr(35) $+ $$1
  .-
  .$iif($me = $right($chan,-1),🎥 Broadcaster options)
  ..$iif($$1 !isop $chan,Mod $$1):.privmsg $chan .mod $1
  ..$iif($$1 isop $chan,Unmod $$1):.privmsg $chan .unmod $1
}
