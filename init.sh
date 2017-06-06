#!/bin/bash
apt-get update && apt-get install -y mosquitto mosquitto-clients ruby ruby-bundler

# setup MQTT server
cat << EOF >> /etc/mosquitto/mosquitto.conf

password_file /etc/mosquitto/passwd
allow_anonymous false
EOF

cat << EOF > /etc/mosquitto/passwd
beamuser:$6$4ZLLLyC9UpERLp8a$BHXtH4S0nuneGi/UMZ14y33zn9rRZcIvZuzDVbZyXJO8kE3KdeCtVF77kOfevegO5PsiRI5Vcr/cKZq4op9Oag==
EOF
chmod 600 /etc/mosquitto/passwd

service mosquitto reload

# clone beamtest repo
cd /home/ubuntu
sudo -u ubuntu git clone https://github.com/j3tm0t0/beamtest.git
cd /home/ubuntu/beamtest
sudo -u ubuntu bundle install

cat <<EOF > /usr/local/bin/loop
#!/bin/bash
while [ true ]
do
	\$*
	sleep 60
done
EOF
chmod +x /usr/local/bin/loop

cat << EOF > /home/ubuntu/.screenrc
startup_message off
vbell off
defshell /bin/bash
defscrollback 1000
shelltitle "$ |bash"
hardstatus alwayslastline "%{.bW}%-w%{.rW}%n %t%{-}%+w %=%{..W} %H %{..Y} %Y %m/%d %C%a "
maptimeout 0
escape "^Xx"

screen 0 loop ruby /home/ubuntu/beamtest/beamtest-tcp.rb
screen 1 loop ruby /home/ubuntu/beamtest/beamtest-http.rb
screen 2 loop mosquitto_sub -d -t '#' -u beamuser -u passwd
EOF

sudo -u ubuntu screen -dmS beamtest -c /home/ubuntu/.screenrc
