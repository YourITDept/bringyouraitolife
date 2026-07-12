# bringyouraitolife
Bring your AI to life

## License
MIT License - THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND

## Connect to Docker container
```bash
docker ps
docker exec -it <container_id_or_name> /bin/bash
```

## Setup the Postgres Database Server - sign into the Postgres server and run these commands
```bash
psql -U dbadmin -d maindb -c "CREATE USER \"abcoctobot88\" WITH PASSWORD 'ChangeToALongPassword';"
psql -U dbadmin -d maindb -c "CREATE DATABASE \"abcoctobot88-paperclip\" OWNER \"abcoctobot88\";"
psql -U dbadmin -d maindb -c "GRANT ALL PRIVILEGES ON DATABASE \"abcoctobot88-paperclip\" TO \"abcoctobot88\";"
psql -U dbadmin -d maindb -c "SELECT datname FROM pg_database ORDER BY datname;"
```

```sql
CREATE USER "abcoctobot88" WITH PASSWORD 'ChangeToALongPassword';
CREATE DATABASE "abcoctobot88-paperclip" OWNER "abcoctobot88";
GRANT ALL PRIVILEGES ON DATABASE "abcoctobot88-paperclip" TO "abcoctobot88";
SELECT datname FROM pg_database ORDER BY datname;
```

## Install Paperclip
```bash
cd $HOME/Paperclip

git config --get remote.origin.url && git branch --show-current

git branch -a

pnpm install

pnpm build

pnpm paperclipai onboard --bind lan

pnpm paperclipai allowed-hostname host.docker.internal
pnpm paperclipai allowed-hostname 127.0.0.1
pnpm paperclipai allowed-hostname localhost

# Turn off telemetry
sed -i ':a;N;$!ba;s/"telemetry":[[:space:]]*{[[:space:]]*"enabled":[[:space:]]*true[[:space:]]*}/"telemetry": {\n    "enabled": false\n  }/g'  ~/.paperclip/instances/default/config.json

vi ~/.paperclip/instances/default/config.json

pnpm paperclipai run

date > AUTORUN.md
```

## Build Docker Image for Docker Hub "youritdepartment/octobot"
Push to the Docker Hub in the cloud. For both AMD and ARM64 architectures, use the following commands:
This works on the Apple M1/M2/M3 ARM64 Mac, but not on the AMD64 Intel/AMD PC. 
```bash
 docker buildx build --platform linux/amd64,linux/arm64 -t youritdepartment/octobot:v53 -t youritdepartment/octobot:latest --push .

 # or use the below when buildiung on two different machines for the two architectures. 
 docker build -t youritdepartment/octobot:v53-amd64 --push .
 docker build -t youritdepartment/octobot:v53-arm64 --push .
 docker buildx imagetools create -t youritdepartment/octobot:latest -t youritdepartment/octobot:v53 youritdepartment/octobot:v53-amd64 youritdepartment/octobot:v53-arm64
 ```