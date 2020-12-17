FROM ruby:2.7

WORKDIR /app
COPY Gemfile .
COPY Gemfile.lock .
RUN bundle install --without test development && bundle clean --force
COPY . /app
EXPOSE 4567
CMD ["ruby", "app.rb"]
