# LoRa_Network

## Installation 

Disclaimer : Docker must be already installed on your machine. Arduino IDE is recommended.

Clone the repo, then execute the *install.sh* script to setup your docker volumes.
Once it's done run this command : 
```bash
docker-compose up -d 
```
It will install the image the first time you run it, after that it will simply act like *docker run*.

To stop the container and clean the subnets, run those commands : 
```bash
docker network prune
docker-compose down
```
