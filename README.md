# Dockerize a rails app with postgres
The dockerize.sh script lets you dockerize an exisitig rails app with postgres easily by adding the necessary docker files and an install script. The script has been developed for MacOS.


## Requirements
Docker has to be installed and running. You should have a working rails app that uses postgres. 

## Using dockerize.sh
Move into the rails project folder. Run the dockerize.sh script in this directory:

~~~~
source dockerize.sh
~~~~

The script overwrites: 
  * config/database.yml
  
and creates the following files:
  * Dockerfile
  * .dockerignore
  * docker-compose.yml
  * install.sh
  
It then runs the install.sh script automatically and deletes itself when finished. Now you can start docker with
 
 ~~~~
 docker-compose up
 ~~~~

and you should see your project running at http://0.0.0.0:3000/ .
