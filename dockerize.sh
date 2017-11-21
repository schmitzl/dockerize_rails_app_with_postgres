#!/bin/bash

echo 'Preparing rails app'
gem install rails bundler
bundle install

echo 'Creating Dockerfile'
touch Dockerfile
cat > Dockerfile << EOF
FROM ruby:2.2.5

# Install apt based dependencies required to run Rails as 
# well as RubyGems. As the Ruby image itself is based on a 
# Debian image, we use apt-get to install those.
RUN apt-get update && apt-get install -y \ 
  build-essential \ 
  nodejs

# Configure the main working directory. This is the base 
# directory used in any further RUN, COPY, and ENTRYPOINT 
# commands.
RUN mkdir -p /app 
WORKDIR /app

# Copy the Gemfile as well as the Gemfile.lock and install 
# the RubyGems. This is a separate step so the dependencies 
# will be cached unless changes to one of those two files 
# are made.
COPY Gemfile Gemfile.lock ./ 
RUN gem install bundler && bundle install --jobs 20 --retry 5

# Copy the main application.
COPY . ./

# Expose port 3000 to the Docker host, so we can access it 
# from the outside.
EXPOSE 3000

# Configure an entry point, so we don't need to specify 
# "bundle exec" for each of our commands.
ENTRYPOINT ["bundle", "exec"]

# The main command to run when the container starts. Also 
# tell the Rails dev server to bind to all interfaces by 
# default.
CMD ["rails", "server", "-b", "0.0.0.0"]
EOF

echo 'Creating .dockerignore'
touch .dockerignore
cat > .dockerignore << EOF
.git*
db/*.sqlite3
db/*.sqlite3-journal
log/*
tmp/*
Dockerfile
README.md
EOF

echo 'Creating docker-compose.yml'
touch docker-compose.yml
cat > docker-compose.yml << EOF
app:
  build: .
  command: rails server -p 3000 -b '0.0.0.0'
  volumes:
    - .:/app
  ports:
    - "3000:3000"
  links:
    - postgres

postgres:
  image: postgres:9.4
  restart: always
  ports:
    - "5432"
  volumes:
    - ./postgres-data:/var/lib/postgresql/data
EOF

echo 'Changing config/database.yml'
cat > config/database.yml << EOF
default: &default 
  adapter: postgresql 
  encoding: unicode 
  pool: 5 
  timeout: 5000 
  username: postgres 
  host: postgres
  port: 5432

development: 
  <<: *default 
  database: app_development

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run 
# "rake". Do not set this db to the same as development or
# production.
test: 
  <<: *default 
  database: app_test
EOF

echo 'Creating install.sh'
touch install.sh
cat > install.sh << EOF
#!/bin/bash

clear

echo -e "\033[1mRunning the application launcher...\033[0m"
echo 'Docker running ?'

if ! [ -x "$(command -v docker)" ]; then echo -e '\033[31mError: Please install docker. Choose your platform on https://docs.docker.com/engine/installation ... \033[0m' >&2; sleep 2; echo ' launching ...'; sleep 2; open 'https://docs.docker.com/engine/installation/'; return; fi
echo -e "\033[32mWell done.\033[0m"

docker-compose down

echo 'Lets compose...'

gem install rails bundler
bundle install

docker-compose build
docker-compose down
sleep 5
echo 'Creating database'
docker-compose run app rake db:create
echo 'Migrating database'
docker-compose run app rake db:migrate
echo 'run "docker-compose up"'
docker-compose up

echo 'Lets see if there is something running'

echo 'Check your browser -> http://0.0.0.0:3000/'
echo '---------------------------------------------------'
echo 'For the future you can start docker by yourself with "docker-compose up".'
EOF

