# Branch
Devlopment Branch

# bringyouraitolife
Bring your AI to life

## Connect to Docker container
```bash
docker ps
docker exec -it <container_id_or_name> /bin/bash
```

## Install Paperclip
```bash
cd $HOME/Paperclip

git config --get remote.origin.url && git branch --show-current

git branch -a

pnpm install

pnpm build

pnpm paperclipai onboard --bind lan

pnpm paperclipai allowed-hostname abc88-paperclip.bringyouraitolife
pnpm paperclipai allowed-hostname host.docker.internal
pnpm paperclipai allowed-hostname 127.0.0.1
pnpm paperclipai allowed-hostname localhost

vi ~/.paperclip/instances/default/config.json

pnpm paperclipai run

date > AUTORUN.md
```
