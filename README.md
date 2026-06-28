# bringyouraitolife
Bring your AI to life

## Install Paperclip
cd $HOME/Paperclip

git config --get remote.origin.url && git branch --show-current
git branch -a

pnpm install
pnpm build

pnpm paperclipai onboard --bind lan

### Allow List: host.docker.internal, 127.0.0.1, localhost, 100.88.192.11, srv1731381.hstgr.cloud, abc88.bringyouraito.life

pnpm paperclipai allowed-hostname abc88-paperclip.bringyouraito.life
pnpm paperclipai allowed-hostname abc88.bringyouraito.life
pnpm paperclipai allowed-hostname srv1731381.hstgr.cloud
pnpm paperclipai allowed-hostname 100.88.192.112
pnpm paperclipai allowed-hostname host.docker.internal
pnpm paperclipai allowed-hostname 127.0.0.1
pnpm paperclipai allowed-hostname localhost

vi ~/.paperclip/instances/default/config.json

pnpm paperclipai run

date > AUTORUN.md
