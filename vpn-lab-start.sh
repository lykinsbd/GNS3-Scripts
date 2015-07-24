#!/bin/bash

# Topology file located in GNS3/Projects directory
TOPFILE="$HOME/GNS3/Projects/Complex-VPN-LAB/Complex-VPN-LAB.gns3"


# Open tunnels to C1.network-notes
printf "\n========[ Opening Tunnels ]========"
ssh -fN -L 25550:c1.network-notes.com:25550 \
-L 2001:c1.network-notes.com:2001 \
-L 2002:c1.network-notes.com:2002 \
-L 2003:c1.network-notes.com:2003 \
-L 2004:c1.network-notes.com:2004 \
-L 2005:c1.network-notes.com:2005 \
-L 2006:c1.network-notes.com:2006 \
-L 2007:c1.network-notes.com:2007 \
-L 2008:c1.network-notes.com:2008 \
-L 2009:c1.network-notes.com:2009 \
-L 2010:c1.network-notes.com:2010 \
-L 2011:c1.network-notes.com:2011 \
-L 2012:c1.network-notes.com:2012 \
-L 2013:c1.network-notes.com:2013 \
-L 2014:c1.network-notes.com:2014 \
-L 2015:c1.network-notes.com:2015 \
-L 2016:c1.network-notes.com:2016 \
-L 2017:c1.network-notes.com:2017 \
-L 2018:c1.network-notes.com:2018 \
-L 2019:c1.network-notes.com:2019 \
-L 2020:c1.network-notes.com:2020 \
-L 2021:c1.network-notes.com:2021 \
cbast.dfw1.rackspace.com



# Open GNS3 with topology file
printf "\n========[ Opening GNS3 ]========\n\n"
/Applications/GNS3.app/Contents/MacOS/GNS3 "$TOPFILE" &


printf "=====[ Waiting 10 seconds for GNS3 and to start and to bring up lab  ]=====\n"
for i in {10..1};do printf "$i, " && sleep 1 ;done


# Monitor and console session:

consoler () {
for i in 2001 2002 2003 2004 2005 2006 2007; do
/usr/bin/osascript <<-EOF
tell application "iTerm"
    make new terminal
    tell the current terminal
        activate current session
        launch session "Default Session"
        tell the last session
            write text "telnet c1.network-notes.com $i"
        end tell
    end tell
end tell
EOF
done
}

consoler

exit
