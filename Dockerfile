###############################################################################
# Run Madek-admin-webapp in a docker container.
# MADE FOR DEVELOPMENT! NOT FOR PRODUCTION!
#
# * no DB included (use docker-compose or local DB)
# * optimized for fast local development:
#   * caching of rubygems and node_modules
#   * caching of precompiled assets
#
###############################################################################

# TODO: use debian (buster) and make ruby-team base image…
FROM ruby:2.6.6

RUN apt-get update -qq \
    && echo "for compiling native gems etc" \
    && apt-get install -y build-essential \
    && echo "for nokogiri" \
    && apt-get install -y libxml2-dev libxslt1-dev \
    && echo "for postgres" \
    && apt-get install -y libpq-dev

# nodejs - TODO: include in base image
RUN apt-get update -qq \
    && apt-get install curl gnupg -yq \
    && curl -sL https://deb.nodesource.com/setup_12.x | bash \
    && apt-get install nodejs -yq

ENV APP_HOME /madek/server/admin-webapp
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

# ruby gems
COPY Gemfile* ./
COPY datalayer/Gemfile* ./datalayer/
RUN bundle install

# application code and all the rest
COPY . $APP_HOME

# # precompile assets
# RUN bin/rails assets:precompile

# NOTE: we dont start the server, this is handled from the
# Dockerfile consumer (like docker-compose). Example command:
# EXPOSE 3000
# CMD ["rails", "server", "-p", "3000", "-b", "0.0.0.0"]