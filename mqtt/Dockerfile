FROM debian

RUN apt-get update

RUN echo "install Mosquitto"
RUN apt-get install -y mosquitto mosquitto-clients

COPY mosquitto.conf /etc/mosquitto/
COPY passwd /etc/mosquitto/

EXPOSE 1883

CMD mosquitto -c /etc/mosquitto/mosquitto.conf
