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

## Development

ruby 2.7 and Bundler is required on your local

### HTTP

#### Setup

```
cd http
# gem install bundler (please install Bundler if your env haven't installed it yet)
bundle install
```

#### Run server on local

```
ruby app.rb
```

#### Run test on local

```
bundle exec rspec spec
```

## Deploy

Undocumented
