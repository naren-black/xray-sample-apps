FROM ruby
RUN apt-get update -qq && apt-get install -y build-essential
RUN gem install bundler --no-ri --no-rdoc
RUN mkdir /app
WORKDIR /app
ADD . /app
RUN bundle install
