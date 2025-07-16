#!/usr/bin/env bash

# lib/greeting/comments.sh - Functions for managing greeting comments

if [[ "${BASH_SOURCE[0]}" != "${0}" ]] && [[ -n "${_LIB_GREETING_COMMENTS_SOURCED:-}" ]]; then
  return 0
fi
_LIB_GREETING_COMMENTS_SOURCED=1

declare -A COMMENT_COLLECTIONS

init_comment_collections() {
  COMMENT_COLLECTIONS[uptime_base]=$(cat <<EOF
such endurance!
running longer than a cat nap!
a true marathon runner!
your system has stamina!
keeping the digital heart beating!
reliability at its finest!
your machine doesn't need much rest!
steadfast like a sentinel cat!
EOF
)

  COMMENT_COLLECTIONS[uptime_days_many]=$(cat <<EOF
This machine has seen many moons! Maybe consider a restart soon?
Impressive uptime - but even servers need catnaps eventually!
Your system has been awake longer than a cat on catnip!
That\'s an impressive streak - your system is very dedicated!
EOF
)

  COMMENT_COLLECTIONS[uptime_days_week]=$(cat <<EOF
This machine has seen many sunrises!
Over a week without a nap? Impressive dedication!
Your system has been purring along for quite some time!
A week of uptime is like a year in cat time!
EOF
)

  COMMENT_COLLECTIONS[uptime_days_few]=$(cat <<EOF
A few days of solid uptime - good foundation!
Your system is well-rested and ready for anything!
Fresh enough to be spry, stable enough to be reliable!
Just the right amount of uptime - like a cat after a perfect nap!
EOF
)

  COMMENT_COLLECTIONS[uptime_hours]=$(cat <<EOF
Recently awakened from its slumber!
Fresh and ready for a productive session!
Just started its day - like a cat after a good nap!
Bright-eyed and bushy-tailed after that recent restart!
EOF
)

  COMMENT_COLLECTIONS[uptime_fallback]=$(cat <<EOF
your system\'s awake time
how long your digital companion has been running
your computer\'s stamina stat
your system\'s marathon record
a measure of digital persistence
EOF
)

  COMMENT_COLLECTIONS[disk_base]=$(cat <<EOF
room for toys
plenty of space for digital yarn balls!
enough room to swing a digital cat!
space for all your code kittens to grow!
storage looking healthy and happy!
your digital storage basket isn\'t overflowing!
plenty of room for your bits and bytes!
a spacious digital playground!
EOF
)

  COMMENT_COLLECTIONS[disk_tb]=$(cat <<EOF
So much space, it\'s like an infinite digital meadow!
With that much space, you could store every cat picture on the internet!
Terabytes of free space? That\'s like having an entire digital country!
Your storage is vast like the steppes of digital Russia!
EOF
)

  COMMENT_COLLECTIONS[disk_gb_plenty]=$(cat <<EOF
So much space, like a vast digital field to roam!
Plenty of room for your digital treasures!
Your disk has more free space than a cat has lives!
A generous amount of space for your creative endeavors!
EOF
)

  COMMENT_COLLECTIONS[disk_gb_low]=$(cat <<EOF
Getting a bit cozy in there - might want to clean up soon!
Your disk could use some grooming before it gets too crowded!
Still room to play, but the digital toy box is filling up!
Consider some spring cleaning before space gets too tight!
EOF
)

  COMMENT_COLLECTIONS[disk_mb]=$(cat <<EOF
Hmm, space is getting a bit snug, like a cozy box!
Your disk space is tighter than a cat in a shoebox!
Running out of room to stretch those digital paws!
Time for some serious cleanup - your disk is almost full!
Storage alert: Digital hoarding detected!
EOF
)

  COMMENT_COLLECTIONS[disk_fallback]=$(cat <<EOF
your digital storage status
space for your digital adventures
room for your code to breathe
storage for your digital treasures
disk space - important for any digital cat
the foundation of your digital home
EOF
)

  COMMENT_COLLECTIONS[ram_base]=$(cat <<EOF
whiskers need more!
needs more RAM to chase all those thoughts!
more RAM, more purr-ower!
RAM is like catnip for your programs!
the digital playground for your processes!
memory is where the magic happens!
your computer\'s short-term memory looks good!
EOF
)

  COMMENT_COLLECTIONS[ram_gb_plenty]=$(cat <<EOF
Plenty of RAM for all the zoomies!
Your computer has room to stretch its digital legs!
Abundant memory for all your coding adventures!
Like a vast savanna for your applications to roam!
EOF
)

  COMMENT_COLLECTIONS[ram_mb_low]=$(cat <<EOF
RAM is a bit tight, perhaps close some unused scratching posts (apps)?
Memory looking a bit crowded, time to clean up some applications!
Your computer might be getting memory-hungry, comrade!
Like a cramped cat carrier - maybe free up some space?
EOF
)

  COMMENT_COLLECTIONS[ram_fallback]=$(cat <<EOF
your computer\'s thinking space
how much scratch space your system has
the playground for your active processes
your system\'s short-term memory
important for keeping your computer purring along
EOF
)

  COMMENT_COLLECTIONS[package_base]=$(cat <<EOF
Your digital territory needs grooming!
Time to sharpen those claws on these updates!
A clean system is a happy system, da?
Updates waiting like mice behind the digital furniture!
Fresh packages, fresh possibilities!
Updates are like fresh treats for your system!
Your package manager is meowing for attention!
EOF
)

  COMMENT_COLLECTIONS[package_many]=$(cat <<EOF
So many updates, it\'s like a field of digital catnip!
Wow, that\'s a lot of packages! Like a yarn shop exploded!
Your system is practically begging for updates!
That\'s quite the collection of outdated packages, comrade!
EOF
)

  COMMENT_COLLECTIONS[package_some]=$(cat <<EOF
Quite a few updates to pounce on!
A decent hunting ground of updates awaits you!
Time for some serious package maintenance, comrade!
Those packages won\'t update themselves, you know!
EOF
)

  COMMENT_COLLECTIONS[package_few]=$(cat <<EOF
Just a few quick updates, easy peasy!
Almost done, just a couple more to go!
A small treat of updates awaits you!
Just a tiny bit of housekeeping needed!
EOF
)

  COMMENT_COLLECTIONS[package_fallback]=$(cat <<EOF
keeping your system up-to-date is important
updates are like digital vitamins for your computer
staying current with updates is good practice
updates often contain important security fixes
EOF
)

  COMMENT_COLLECTIONS[task_base]=$(cat <<EOF
Let\'s hunt them down together, da?
Time to pounce on those tasks!
Show them who\'s the boss, comrade!
Your task list awaits your mighty paws!
Those tasks won\'t complete themselves, you know!
Each completed task is like catching a digital mouse!
The satisfaction of crossing off tasks is purr-fect!
Conquering your task list is today\'s adventure!
EOF
)

  COMMENT_COLLECTIONS[task_morning]=$(cat <<EOF
Morning is the perfect time to tackle your most challenging tasks!
A productive morning sets the tone for the whole day!
Fresh morning minds solve problems best - tackle those tasks now!
EOF
)

  COMMENT_COLLECTIONS[task_midday]=$(cat <<EOF
Mid-day is great for knocking out those medium-difficulty tasks!
Use your lunch break wisely - maybe complete a quick task before eating?
The day is half done, but your productivity can still be at 100%!
EOF
)

  COMMENT_COLLECTIONS[task_afternoon]=$(cat <<EOF
Afternoon slump? Completing a task will give you an energy boost!
Finish strong today by checking off a few more items!
Just a few more hours in the workday - make them count!
EOF
)

  COMMENT_COLLECTIONS[task_evening]=$(cat <<EOF
Evening is good for reflective tasks and planning tomorrow!
Wind down your day by completing something simple but satisfying!
A few tasks completed now means less stress tomorrow morning!
EOF
)

  COMMENT_COLLECTIONS[task_night]=$(cat <<EOF
Night owl productivity can be amazing - but don\'t forget to sleep eventually!
Late night focus can help knock out complex tasks with fewer distractions!
Burning the midnight oil? Make sure it\'s for something important!
EOF
)

  COMMENT_COLLECTIONS[task_fallback]=$(cat <<EOF
completing tasks is satisfying
check them off one by one
the journey of a thousand miles begins with a single task
breaking down big tasks makes them easier to complete
EOF
)

  COMMENT_COLLECTIONS[greeting_morning_early]=$(cat <<EOF
Wow, you're up early! Even cats sleep more than that!
The early bird catches the worm, but the early cat catches the best code!
Early coding sessions are often the most productive!
EOF
)

  COMMENT_COLLECTIONS[greeting_morning]=$(cat <<EOF
Early cat catches the digital mouse!
A fresh mind makes for elegant solutions!
Morning is the perfect time to tackle complex problems!
EOF
)

  COMMENT_COLLECTIONS[greeting_morning_late]=$(cat <<EOF
Perfect time for a productive morning coding session!
The day is young and full of possibilities!
Morning energy channeled into code is a beautiful thing!
EOF
)

  COMMENT_COLLECTIONS[greeting_afternoon]=$(cat <<EOF
Afternoon energy is purrfect for coding!
Midday is great for making progress on big projects!
The sun is high and so is your potential right now!
EOF
)

  COMMENT_COLLECTIONS[greeting_afternoon_mid]=$(cat <<EOF
Avoiding the post-lunch coding dip? Good strategy!
Fighting through the afternoon lull shows true dedication!
A second wind of productivity incoming!
EOF
)

  COMMENT_COLLECTIONS[greeting_afternoon_late]=$(cat <<EOF
The day is winding down, but your productivity doesn't have to!
Late afternoon focus can lead to great breakthroughs!
Squeeze in a bit more productivity before evening!
EOF
)

  COMMENT_COLLECTIONS[greeting_evening]=$(cat <<EOF
Evening coding sessions can be the most productive!
The quiet of evening creates the perfect coding atmosphere!
As the day winds down, your focus can ramp up!
EOF
)

  COMMENT_COLLECTIONS[greeting_evening_late]=$(cat <<EOF
Night owl coding? Sometimes the best ideas come after dark!
Burning the midnight oil on your projects - dedication!
The nighttime quiet helps concentrate on complex problems!
EOF
)

  COMMENT_COLLECTIONS[greeting_night]=$(cat <<EOF
Midnight coding? Your dedication is impressive, comrade!
Night owls often make the best programmers!
The world sleeps while you build it!
EOF
)

  COMMENT_COLLECTIONS[greeting_night_late]=$(cat <<EOF
The quietest hours are best for deep work... and for cats prowling!
In the depths of night, the most elegant solutions emerge!
Solving problems while the world sleeps - truly dedicated!
EOF
)

  COMMENT_COLLECTIONS[greeting_night_predawn]=$(cat <<EOF
Even the most nocturnal cats take breaks, remember to rest soon!
Pre-dawn coding - when determination meets inspiration!
Soon the sun will rise on your accomplishments!
EOF
)
}

get_random_comment() {
  local collection_name="$1"
  local collection_content="${COMMENT_COLLECTIONS[$collection_name]}"

  if [[ -z "$collection_content" ]]; then
    echo "No comments available for $collection_name"
    return 1
  fi

  local lines=()
  local line
  local old_ifs="$IFS"
  IFS=$'\\n'
  while IFS= read -r line || [[ -n "$line" ]]; do
      line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      if [[ -n "$line" ]]; then
          lines+=("$line")
      fi
  done <<< "$collection_content"
  IFS="$old_ifs"

  if [[ ${#lines[@]} -eq 0 ]]; then
    echo "No usable comments in $collection_name"
    return 1
  fi

  echo "${lines[$((RANDOM % ${#lines[@]}))]}"
}

get_comment_collection() {
  local result=()
  local line

  for collection_name in "$@"; do
    if [[ -n "${COMMENT_COLLECTIONS[$collection_name]}" ]]; then
      local old_ifs="$IFS"
      IFS=$'\\n'
      while IFS= read -r line || [[ -n "$line" ]]; do
          line=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
          if [[ -n "$line" ]]; then
            result+=("$line")
          fi
      done <<< "${COMMENT_COLLECTIONS[$collection_name]}"
      IFS="$old_ifs"
    fi
  done

  if [[ ${#result[@]} -eq 0 ]]; then
    echo "A fancy digital cat comment should be here"
    return 0
  fi

  echo "${result[$((RANDOM % ${#result[@]}))]}"
}
