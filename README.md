# beamtest

Beamtest is a server to check if your SORACOM Beam settings is correct.

## Where is it hosted?

https://beamtest.soracom.io:4567
tcps://beamtest.soracom.io:1234
mqtts://beamtest.soracom.io:8883

## How to run server on your local

Prerequisites: docker

### HTTP

```
docker build http
docker run -d -p 4567:4567 --name beamtest-http IMAGE_ID
```

### TCP

You can access 1234 port by TCP protocol (not TCPS).

```
docker build tcp
docker run -d -p 1234:1234 --name beamtest-tcp IMAGE_ID
```
