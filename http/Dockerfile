FROM ruby:2.7

WORKDIR /app
COPY Gemfile .
RUN bundle install && bundle clean --force
COPY . /app
EXPOSE 4567
CMD ["ruby", "app.rb"]
