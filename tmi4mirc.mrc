/*
* TMI 4 mIRC
* Twitch Messaging Interface enhancements
*
* @author Geir André Halle
* @version 0.0.0811
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
  if ((!$timer(tmi4input- [ $+ [ $target ] ]) ) && ($msgtags(user-type).key || $msgtags(subscriber).key || $msgtags(turbo).key)) {
    echo $color(info) -t $target * Channel privileges: $iif($msgtags(user-type).key,$msgtags(user-type).key) $iif($right($target,-1) == $me,broadcaster) $iif($msgtags(subscriber).key,subscriber) $iif($msgtags(turbo).key,turbo)
  }
  haltdef 
}
raw HOSTTARGET:*:{ 
  if ($2 != -) {
    echo $color(info) -t $1 * Now hosting $+($chr(2),$2,$chr(2)) $iif($3 != -,for $+($chr(2),$3,$chr(2)) viewers,)
  }
  haltdef
}
on 1:INPUT:#:{ if ($left($1-,1) != /) .timertmi4input- [ $+ [ $chan ] ] 1 2 return }
on ^1:NOTICE:*:#:{
  if (($server == tmi.twitch.tv) && ($nick == tmi.twitch.tv)) {
    if ($2 != hosting) { echo $color(info) -t $chan * $1- }
    haltdef
  }
}
on ^1:TEXT:*:#:{
  if ($server == tmi.twitch.tv) { 
    if (($nick == twitchnotify) || ($nick == jtv)) {
      if (!$istok($1-,to,32)) { echo $color(info) -t $chan * $1- }
      haltdef
    }
    if ($msgtags(user-type).key == staff) cline -m 13 $chan $nick
    elseif ($msgtags(user-type).key == admin) cline -m 13 $chan $nick
    elseif ($msgtags(user-type).key == globalmod) cline -m 13 $chan $nick

    if ($tmiStyling) {
      var %tmiChatter = $iif($right($chan,-1) == $nick,$tmiBadge(broadcaster),$iif($msgtags(user-type).key,$tmiBadge($msgtags(user-type).key)))
      var %tmiChatter = %tmiChatter $iif($msgtags(turbo).key == 1,$tmiBadge(turbo))
      var %tmiChatter = %tmiChatter $iif($msgtags(subscriber).key == 1,$tmiBadge(subscriber))
      var %tmiChatter = %tmiChatter $tmiDisplayname($msgtags(display-name).key) $+ : $1- 
      echo -t $chan %tmiChatter
      haltdef
    }
  }
}

#tmiStyling on
alias -l tmiStyling return $true

alias tmiBadge {
  var %tmibadge
  if ($1 == broadcaster) { var %tmibadge = $chr(3) $+ 0,4 🎥 $chr(3) }
  elseif ($1 == staff) { var %tmibadge = $chr(3) $+ 0,1 🔧 $chr(3) }
  elseif ($1 == admin) { var %tmibadge = $chr(3) $+ 0,7 ⛊ $chr(3) }
  elseif ($1 == globalmod) { var %tmibadge = $chr(3) $+ 0,3 🔨 $chr(3) }
  elseif ($1 == mod) { var %tmibadge = $chr(3) $+ 0,3 ⚔ $chr(3) }
  elseif ($1 == turbo) { var %tmibadge = $chr(3) $+ 0,6 🔋 $chr(3) }
  elseif ($1 == subscriber) { var %tmibadge = $chr(22) ★ $chr(22) }
  return %tmibadge
}

alias -l tmiDisplayname return $+(,$tmiHexcolor($msgtags(color).key),$$1,)
alias -l tmiHexcolor {
  tokenize 46 $regsubex($1,/#?([a-f\d]{2})/gi,$base(\1,16,10) .)
  var %i = 0, %c, %d = 200000
  while %i < 16 {
    tokenize 32 $1-3 $replace($rgb($color(%i)),$chr(44),$chr(32))
    if $calc(($1 -$4)^2 + ($2 -$5)^2 + ($3 -$6)^2) < %d {
      %c = %i
      %d = $v1
    }
    inc %i
  }
  return %c
}
#tmiStyling end
