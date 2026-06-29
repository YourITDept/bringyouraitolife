# bringyouraitolife
Bring your AI to life

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
