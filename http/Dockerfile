FROM ruby:2.7

WORKDIR /app
COPY Gemfile .
COPY Gemfile.lock .
RUN bundle update --bundler
RUN bundler --version
RUN bundle config set without 'test development'
RUN bundle config set deployment 'true'
RUN bundle install && bundle clean --force
COPY . /app
EXPOSE 4567
CMD ["ruby", "app.rb"]
