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
  if ($msgtags(user-type).key || $msgtags(subscriber).key || $msgtags(turbo).key) {
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
  }
}
