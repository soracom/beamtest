FROM ruby:2.6

WORKDIR /app
COPY Gemfile .
RUN bundle install && bundle clean
COPY . /app
EXPOSE 4567
CMD ["ruby", "app.rb"]
