# bringyouraitolife 
Project Octobot - Bring your AI to life

## License
License: MIT License - THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND (see LICENSE file)

## Connect to Docker container
```bash
docker ps
docker exec -it <container_id_or_name> /bin/bash
```

## Visual Code Profile
See the import the VS Profile file "Octobot.code-profile" into your VS Code for best results in management of your Docker enviroment.

## Install Paperclip - Run the "Advanced setup" option for onboarding and do not start during onboarding
```bash
cd $HOME/Paperclip
pnpm install
pnpm build

pnpm paperclipai onboard --bind lan

```

### Configure a few options then start server
```bash
pnpm paperclipai allowed-hostname host.docker.internal
pnpm paperclipai allowed-hostname 127.0.0.1
pnpm paperclipai allowed-hostname localhost
```

### Turn off telemetry if you like
```bash
sed -i ':a;N;$!ba;s/"telemetry":[[:space:]]*{[[:space:]]*"enabled":[[:space:]]*true[[:space:]]*}/"telemetry": {\n    "enabled": false\n  }/g'  ~/.paperclip/instances/default/config.json
```

### If you want to review the config file before starting you can edit it with this command
```bash
vi ~/.paperclip/instances/default/config.json
```

### Run the server to make sure all is working and can onboard
```bash
pnpm paperclipai run
```

### This will auto start the Paperclip server when the Docker container starts
```bash
date > AUTORUN.md
```

## Build Docker Image for Docker Hub "youritdepartment/octobot"
Push to the Docker Hub in the cloud. For both AMD and ARM64 architectures, use the following commands:
This works on the Apple M1/M2/M3 ARM64 Mac, but not on the AMD64 Intel/AMD PC. 
```bash
 docker buildx build --platform linux/amd64,linux/arm64 -t youritdepartment/octobot:v61 -t youritdepartment/octobot:latest --push .
 ```

 ### or use the below when buildiung on two different machines for the two architectures. 
 ```bash
 docker build --platform linux/amd64 -t youritdepartment/octobot:v61-amd64 --push .
 docker build --platform linux/arm64 -t youritdepartment/octobot:v61-arm64 --push .
 docker buildx imagetools create -t youritdepartment/octobot:latest -t youritdepartment/octobot:v61 youritdepartment/octobot:v61-amd64 youritdepartment/octobot:v61-arm64
 ```

## Setup the Postgres Database Server - sign into the Postgres server and run these commands
URL: postgresql://abcoctobot88:ChangeToALongPassword@sharedpostgres00:5432/abcoctobot88-paperclip
```bash
psql -U dbadmin -d maindb -c "CREATE USER \"abcoctobot88\" WITH PASSWORD 'ChangeToALongPassword';"
psql -U dbadmin -d maindb -c "CREATE DATABASE \"abcoctobot88-paperclip\" OWNER \"abcoctobot88\";"
psql -U dbadmin -d maindb -c "GRANT ALL PRIVILEGES ON DATABASE \"abcoctobot88-paperclip\" TO \"abcoctobot88\";"
psql -U dbadmin -d maindb -c "SELECT datname FROM pg_database ORDER BY datname;"
```
### Or run the following command in the VS Code Postgres SQL editor
```sql
CREATE USER "abcoctobot88" WITH PASSWORD 'ChangeToALongPassword';
CREATE DATABASE "abcoctobot88-paperclip" OWNER "abcoctobot88";
GRANT ALL PRIVILEGES ON DATABASE "abcoctobot88-paperclip" TO "abcoctobot88";
SELECT datname FROM pg_database ORDER BY datname;
```