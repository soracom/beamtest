FROM ruby:2.7

RUN apt-get update

RUN echo "install netcat(nc)"
RUN apt-get install -y netcat

WORKDIR /app
COPY . /app

EXPOSE 1234

CMD ["ruby", "app.rb"]
