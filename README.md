# beamtest

Beamtest is a server to check if your SORACOM Beam settings is correct.

## Where is it hosted?

https://beamtest.soracom.io:4567
tcps://beamtest.soracom.io:1234
mqtts://beamtest.soracom.io:8883

## How to start a server on your local using Docker

Prerequisites: docker

### HTTP

You can access a 4567 port by HTTP protocol (not HTTPS).

```
docker build http
docker run -d -p 4567:4567 --name beamtest-http IMAGE_ID
```

### TCP

You can access a 1234 port by TCP protocol (not TCPS).

```
docker build tcp
docker run -d -p 1234:1234 --name beamtest-tcp IMAGE_ID
```

### MQTT

You can access an 1883 port by MQTT protocol (not MQTTS).

```
docker build mqtt
docker run -d -p 1883:1883 --name beamtest-mqtt IMAGE_ID
```
## Development
### HTTP

ruby 2.7 and Bundler is required on your local

#### Setup

```
cd http
# gem install bundler (please install Bundler if your env haven't installed it yet)
bundle install
ruby app.rb
```
#### Test

```
bundle exec rspec spec
```

### TCP

```
cd tcp
ruby app.rb
```

## Deploy

beamtest is running on a 'beamtest' cluster on Amazon ECS (tamasui account).

You need to update docker images on ECR and update services. (ECS task definitions point the LATEST images)

- 762707677580.dkr.ecr.ap-northeast-1.amazonaws.com/beamtest/beamtest-http:latest
- 762707677580.dkr.ecr.ap-northeast-1.amazonaws.com/beamtest/beamtest-tcp:latest
- 762707677580.dkr.ecr.ap-northeast-1.amazonaws.com/beamtest/beamtest-mqtt:latest
