FROM ruby:3.1.2

RUN apt-get update -qq && apt-get install -y nodejs
WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN bundle install

EXPOSE 3000