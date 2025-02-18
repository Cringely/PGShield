#!/bin/bash
#
# Title:      PGBlitz (Reference Title File)
# Author(s):  Admin9705 - Deiteq
# URL:        https://pgblitz.com - http://github.pgblitz.com
# GNU:        General Public License v3.0
################################################################################
source /opt/plexguide/menu/functions/functions.sh

question1 () {
touch /var/plexguide/auth.bypass

a7=$(cat /var/plexguide/auth.bypass)
if [[ "$a7" != "good" ]]; then shieldcheck; fi
echo good > /var/plexguide/auth.bypass

touch /var/plexguide/pgshield.emails
mkdir -p /var/plexguide/auth/

domain=$(cat /var/plexguide/server.domain)

tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛡️  PG Shield | http://pgshield.pgblitz.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💬  PG Shield requires Google Web Auth Keys! Visit the link above!

[1] Set Web Client ID & Secret
[2] Authorize User(s)
[3] Protect / UnProtect PG Apps
[4] Deploy PG Shield

[Z] Exit

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
phase1
}

phase1 () {

read -p 'Type a Number | Press [ENTER]: ' typed < /dev/tty

case $typed in
    1 )
        webid
        phase1 ;;
    2 )
        email
        phase1 ;;
    3 )
        appexempt
        phase1 ;;
    4 )
        # Sanity Check to Ensure At Least 1 Authorized User Exists
        touch /var/plexguide/pgshield.emails
        efg=$(cat "/var/plexguide/pgshield.emails")
        if [[ "$efg" == "" ]]; then
        echo
        echo "SANITY CHECK: No Authorized Users have been Added! Exiting!"
        read -p 'Acknowledge Info | Press [ENTER] ' typed < /dev/tty; question1; fi

        # Sanity Check to Ensure that Web ID ran domaincheck
        file="/var/plexguide/auth.idset"
        if [ ! -e "$file" ]; then
        echo
        echo "SANITY CHECK: You Must @ Least Run the Web ID Interface Once!"
        read -p 'Acknowledge Info | Press [ENTER] ' typed < /dev/tty; question1; fi

        # Sanity Check to Ensure Ports are closed
        touch /var/plexguide/server.ports
        ports=$(cat "/var/plexguide/server.ports")
        if [ "$ports" != "127.0.0.1:" ]; then
        echo
        echo "SANITY CHECK: Ports are open, PGShield cannot be enabled until they are closed due to security risks!"
        read -p 'Acknowledge Info | Press [ENTER] ' typed < /dev/tty; question1; fi

        touch /var/plexguide/pgshield.compiled
        rm -r /var/plexguide/pgshield.compiled
        while read p; do
          echo -n "$p," >> /var/plexguide/pgshield.compiled
        done </var/plexguide/pgshield.emails

        ansible-playbook /opt/pgshield/pgshield.yml
        bash /opt/pgshield/rebuild.sh
        question1 ;;
    z )
        exit ;;
    Z )
        exit ;;
    * )
        question1 ;;
esac
}

appexempt() {
bash /opt/coreapps/apps/_appsgen.sh > /var/plexguide/app.list
bash /opt/communityapps/apps/_appsgen.sh >> /var/plexguide/app.list
sort -o /var/plexguide/app.list /var/plexguide/app.list
ls -l /var/plexguide/auth | awk '{ print $9 }' > /var/plexguide/pgshield.ex15

tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛡️  PG Shield ~ App Protection | http://pgshield.pgblitz.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Disable PGShield for a single app
2. Enable PGShield for a single app
3. Reset & Enable PGShield for all apps
Z. Exit

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
phase3
}

phase3() {
read -p 'Type a Number | Press [ENTER]: ' typed < /dev/tty

case $typed in
    1 )
        phase31
        appexempt ;;
    2 )
        phase21
        appexempt ;;
    3 )
        emptycheck=$(cat /var/plexguide/pgshield.ex15)
        if [[ "$emptycheck" == "" ]]; then echo;
        read -p 'No Apps have PGShield Disabled! Exiting | Press [ENTER]'; appexempt; fi
        rm -rf /var/plexguide/auth/*
        echo ""
        echo "NOTE: Does not take effect until PG Shield is redeployed!"
        read -p 'Acknowledge Info | Press [ENTER] ' typed < /dev/tty; email
        appexempt;;
    z )
        question1 ;;
    Z )
        question1 ;;
    * )
        appexempt ;;
esac

}

phase31(){
  touch /var/plexguide/app.list
  while read p; do
    sed -i -e "/$p/d" /var/plexguide/app.list
  done </var/plexguide/pgshield.ex15

  ### Blank Out Temp List
  rm -rf /var/plexguide/program.temp && touch /var/plexguide/program.temp

  ### List Out Apps In Readable Order (One's Not Installed)
  num=0
  while read p; do
    echo -n $p >> /var/plexguide/program.temp
    echo -n " " >> /var/plexguide/program.temp
    num=$[num+1]
    if [ "$num" == 7 ]; then
      num=0
      echo " " >> /var/plexguide/program.temp
    fi
  done </var/plexguide/app.list

  notrun=$(cat /var/plexguide/program.temp)

tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛡️  PG Shield ~ Disable Shield for an app | http://pgshield.pgblitz.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📂 Apps currently protected by PGShield:

$notrun

💬 Quitting? TYPE > exit
EOF
  read -p '🌍 Type APP to disable PGShield | Press [ENTER]: ' typed < /dev/tty

if [[ "$typed" == "exit" ]]; then appexempt; fi

grep -w "$typed" /var/plexguide/program.temp > /var/plexguide/check55.sh
usercheck=$(cat /var/plexguide/check55.sh)

if [[ "$usercheck" == "" ]]; then echo;
read -p 'App does not exist! | Press [ENTER] ' note < /dev/tty; appexempt; fi

touch /var/plexguide/auth/$typed
echo
echo "NOTE: No effect until PGShield or the app is redeployed!"
read -p '🌍 Acknoweldge! | Press [ENTER] ' note < /dev/tty; appexempt
}

phase21(){

  emptycheck=$(cat /var/plexguide/pgshield.ex15)
  if [[ "$emptycheck" == "" ]]; then echo;
  read -p 'No apps are exempt! Exiting | Press [ENTER]'; appexempt; fi
  ### Blank Out Temp List
  rm -rf /var/plexguide/program.temp && touch /var/plexguide/program.temp

  ### List Out Apps In Readable Order (One's Not Installed)
  num=0
  while read p; do
    echo -n $p >> /var/plexguide/program.temp
    echo -n " " >> /var/plexguide/program.temp
    num=$[num+1]
    if [ "$num" == 7 ]; then
      num=0
      echo " " >> /var/plexguide/program.temp
    fi
  done </var/plexguide/pgshield.ex15

  notrun=$(cat /var/plexguide/program.temp)

tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛡️  PG Shield ~ Enable Shield for an app | http://pgshield.pgblitz.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📂 Apps NOT currently protected by PGShield:

$notrun

💬 Quitting? TYPE > exit
EOF
  read -p '🌍 Type app to enable PGShield | Press [ENTER]: ' typed < /dev/tty

  if [[ "$typed" == "exit" ]]; then appexempt; fi

grep -w "$typed" /var/plexguide/pgshield.ex15 > /var/plexguide/check55.sh
usercheck=$(cat /var/plexguide/check55.sh)

if [[ "$usercheck" == "" ]]; then echo;
read -p 'App does not exist! | Press [ENTER] ' note < /dev/tty; appexempt; fi

rm -rf /var/plexguide/auth/$typed
echo
echo "NOTE: No effect until PG Shield or the app is redeployed!"
read -p '🌍 Acknoweldge! | Press [ENTER] ' note < /dev/tty; appexempt
}

webid() {
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔑 Google Web Keys - Client ID       📓 Reference: pgshield.pgblitz.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Quitting? Type > exit
NOTE: Visit reference for Google Web Auth Keys

EOF

read -p '↘️  Web Client ID     | Press [Enter]: ' public < /dev/tty
if [ "$public" = "exit" ]; then question1; fi
echo "$public" > /var/plexguide/shield.clientid

read -p '↘️  Web Client Secret | Press [Enter]: ' secret < /dev/tty
if [ "$secret" = "exit" ]; then question1; fi
echo "$secret" > /var/plexguide/shield.clientsecret

read -p '🔑 Client ID & Secret Set |  Press [ENTER] ' public < /dev/tty
touch /var/plexguide/auth.idset
question1
}

email() {
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛡️  PG Shield ~ Trusted Users | http://pgshield.pgblitz.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. E-Mail: Add User
2. E-Mail: Remove User
3. E-Mail: View Authorization List
4. E-Mail: Remove All Users (Stops PG Shield)
Z. Exit

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
phase2
}

phase2 () {

read -p 'Type a Number | Press [ENTER]: ' typed < /dev/tty

case $typed in
    1 )
        echo
        read -p 'User Email to Add | Press [ENTER]: ' typed < /dev/tty

        emailcheck=$(echo $typed | grep "@")
        if [[ "$emailcheck" == "" ]]; then
          read -p 'Invalid E-Mail! | Press [ENTER] ' note < /dev/tty; email; fi

        usercheck=$(cat /var/plexguide/pgshield.emails | grep $typed )
        if [[ "$usercheck" != "" ]]; then
          read -p 'User Already Exists! | Press [ENTER] ' note < /dev/tty; email; fi
          read -p 'User Added | Press [ENTER] ' note < /dev/tty;
        echo "$typed" >> /var/plexguide/pgshield.emails
        email ;;
    2 )
        echo
        read -p 'User Email to Remove | Press [ENTER]: ' typed < /dev/tty
        testremove=$(cat /var/plexguide/pgshield.emails | grep $typed )
        if [[ "$testremove" == "" ]]; then
        read -p 'User does not exist | Press [ENTER] ' typed < /dev/tty; email; fi
        sed -i -e "/$typed/d" /var/plexguide/pgshield.emails
        echo ""
        echo "NOTE: Does not take effect until PG Shield is redeployed!"
        read -p 'Removed User | Press [ENTER] ' typed < /dev/tty; email
        email ;;
    3 )
        echo
        echo "Current Authorized E-Mail Addresses"
        echo ""
        cat /var/plexguide/pgshield.emails
        echo
        read -p 'Finished? | Press [ENTER] ' typed < /dev/tty; email
        email ;;
    4 )
        test=$(cat /var/plexguide/pgshield.emails | grep "@")
        if [[ "$test" == "" ]]; then email; fi
        docker stop oauth
        rm -r /var/plexguide/pgshield.emails
        touch /var/plexguide/pgshield.emails
        echo
        docker stop oauth
        read -p 'All Prior Users Removed! | Press [ENTER] ' typed < /dev/tty
        email ;;
    z )
        question1 ;;
    Z )
        question1 ;;
    * )
        email ;;
esac
}

shieldcheck() {
  domaincheck=$(cat /var/plexguide/server.domain)
  touch /var/plexguide/server.domain
  touch /tmp/portainer.check
  rm -r /tmp/portainer.check
  wget -q "https://portainer.${domaincheck}" -O /tmp/portainer.check
  domaincheck=$(cat /tmp/portainer.check)
  if [ "$domaincheck" == "" ]; then

tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛡️  PG Shield ~ Unable to talk to Portainer | pgshield.pgblitz.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Did you forget to enable Traefik?"
2. Valdiate if the portainer subdomain is working?"
3. Validate Portainer is deployed?"
4. oauth.${domain} cname in your DNS? (CloudFlare Users)"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
read -p 'Acknowledge Info | Press [ENTER] ' typed < /dev/tty
exit; fi
}

question1
