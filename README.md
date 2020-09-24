# Ocean

## Setup

### Requirements
* [asdf](https://github.com/asdf-vm/asdf) - Program version management
* [ansible](https://docs.ansible.com/ansible/2.7/installation_guide/intro_installation.html)
`brew install ansible`
* [Erlang/OTP](https://github.com/erlang/otp) version in .tools-versions
* [Elixir](https://elixir-lang.org/) version in .tools-versions
* [Phoenix](https://phoenixframework.org/) version in mix.exs
* [Postgres 11.3](https://www.postgresql.org/)
* [Node.js](https://nodejs.org/en/) version in .tools-versions
* [Yarn](https://yarnpkg.com/en/) version in assests/package.json
* GitHub for code storage

#### Setting up `yarn`
This project depends on `yarn` for managing dependencies and building assets with `parcel`. After all the ansible setup has been completed, you'll need to install `yarn` using the installation method suggested for the server's OS here: https://yarnpkg.com/en/docs/install#debian-stable.

Without this, you'll get an error that `yarn` could not be found and `./scripts/build-release.sh` will fail.

### Build and Run
To start your Phoenix server:

* Install dependencies with `mix deps.get`
* Create and migrate your database with `mix ecto.create && mix ecto.migrate`
* Install Node.js dependencies with `cd assets && yarn install`
* Start Phoenix endpoint with `mix phx.server`
* Start the asset server with `cd assets && yarn watch`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

To run tests locally, we no longer depend on selenium and just use `chromedriver` directly:

* Install Chromedriver with  `brew install chromedriver`
* In another terminal window, run `mix test`


### Seed data
* The seeds file will delete items in the database and seed new data
* Run `mix run priv/repo/seeds.exs`

There is a separate `prod_seeds.exs` file that only creates an admin user for production environments.

### Clearing All Data
```elixir
alias Oceanconnect.Repo
alias Oceanconnect.Accounts
alias Oceanconnect.Accounts.{Company, User}
alias Oceanconnect.Auctions
alias Oceanconnect.Auctions.AuctionEventStorage
alias Oceanconnect.Auctions.{Auction, AuctionSuppliers, Fuel, Port, Vessel, Barge}

Repo.delete_all(AuctionEventStorage)
Repo.delete_all("auctions_barges")
Repo.delete_all("company_ports")
Repo.delete_all("company_barges")
Repo.delete_all(AuctionSuppliers)
Repo.delete_all(Barge)
Repo.delete_all(Auction)
Repo.delete_all(User)
Repo.delete_all(Vessel)
Repo.delete_all(Fuel)
Repo.delete_all(Port)
Repo.delete_all(Company)
```

### Configuring
Updates can be made to the `config/dev.secret.exs` and `config/prod.secret.exs` to override default behaviors specified
in the `config/config.exs` and `config/dev.exs` or `config/prod.exs` files. Changes made to the `config/prod.secret.exs`
will require re-building/deploying (manually or through CircleCI deployment) before they will take effect.

# OCM Notes
```
       __ Users __________________
      /    |           \          \
Buyers     Suppliers     Admin      Observers
   |          |   \
 Vessels   Ports   Barges
   |        /
Auction-----
```

## Auction Information
Auctions can be 2 basic types (Spot and Term) with the same basic behavior (especially during live bidding). An auction
can have the following statuses:

* DRAFT - no scheduled start_date entered
* PENDING - has not started
* OPEN - active auction in bidding phase
* DECISION - bidding is closed and buyer is deciding on winning bid
* CLOSED - buyer accepted a winning bid
* EXPIRED - buyer did not select a winning bid before the decision time expired
* CANCELED - auction was canceled by the buyer or admin

The final 3 statuses [CLOSED, EXPIRED, CANCELED] known as `finalized` states are categorized as historical auctions.

## Code Architecture
This codebase implements an event driven architecture and uses an `AuctionCache` Genserver to keep auction details and auction state (including the current status) for auctions not in `finalized` state in memory for fast retrieval (auctions in a `finalized` state are stored in a `FinalizedStateCache`). All updates to the databased auction need to also update the `AuctionCache` (fully preloaded). Commands are processed by the AuctionStore for the type of auction, producing events that are processed and emitted. Auction events are persisted (with the event payload) and can be used to rebuild the state of an auction at any point in time. These auction events are all processed by an AuctionEventHandler that takes appropriate action for each event in FIFO. Auction bids (submitted when PENDING or OPEN) are time-stamped upon receipt by the server and processed sequentially, triggering any auto-bids necessary based on any minimum bids submitted by suppliers. All notifications for auction events are published using the following:

* Phoenix Pub-Sub - for internal notifications to process that need to asynchronously react
* AuctionNotifier - for broadcasting live updates to clients subscribed to the respective auction channel
* EmailNotifier - for sending out emails for relevant events
* DelayedNotifications - for sending emails that are sent with a delay from the trigger event (staring soon emails, etc)

## App Users
The application is intended to be used by companies with most access and authorization based upon the company. Users exist to allow for personalized login and traceability of interactions (including chat messages and targeted emails). A user belongs to only one company, and all information for that company can be seen by it's users (there's no private information within a company). Auction information is restricted based on the role a company plays in that auction (buyer or supplier) and can be further restricted based on auction configuration (ex. anonymous bidding auctions).

There are also 2 special users (admin and observer) that should only be associated with a company that contains no other user types (i.e. an admin user belongs to a company that only has admin users, etc).

**Observers**
An observer is a user/company that can be used to demo the application to prospective clients. An admin can invite an observer to view an auction and receive all the live updates as the auction changes. Observers will be able to see supplier information, but all buyer and vessel information is anonymous. An observer can only view an auction, not take any action. Buyers and suppliers are not able to tell if an auction is being observed.

**Admin**
An admin has administrative rights to the application which allows them to see and control anything. Admins can take action as themselves or they can `impersonate` any other user in the system. While impersonating another user, the admin's view and rights would represent that of the impersonated user, but any action taken would log the admin in the database. The admin can also setup and manage companies, users, ports, vessels, etc using the Admin Panel.

### Ports
-  have an associated Timezone for ETD ETA of Ship Arrival on Auction

# Dev Ops

## Production & Staging Logs
You can access the production and staging applicaiton log via the journalctl
utility once logged in via ssh. (The `sudo` command is not needed if logged
in at the `root` user.)
```sh
sudo journalctl -t oceanconnect -n 500
```

## Releasing

### Git Process for Branch Merging
**Use Pull Requests for new changes. Master has been protected from force pushes.**

* Run `git checkout master`
* Run `git pull --rebase`
* Run `git checkout [branch]`
* Run `git rebase master`
* Confirm all tests still pass with `mix test`
* Run `git push -f`
* Run `git checkout master`
* Run `git merge --no-ff [branch]`
* Run `git push origin master`

### Staging
CircleCI automatically deploys the `master` branch to the staging environment.

### Production
CircleCI automatically deploys SemVer (v#.#.#) tags to production.

**Note:**
Setup CircleCI SSH to servers using: `ssh-copy-id -f -i ./.circleci/oceanconnect_deploy.pub deploy@<server>`

#### Manual deployment
We're using Ansible to manage server provisioning and deployments. For the most part, doing a new deploy involves:

1. Log into the build server with `ssh -A deploy@oceanconnect`
2. `cd ~/build/oceanconnect/`
3. Run `./scripts/build-release.sh` to build the new release binary
4. Run any necessary migrations with `./scripts/db-migrate.sh`
5. Deploy with `./scripts/deploy-local.sh`

New users will need to add their account information to `ansible/inventory/group_vars/all/users.yml` and have the `manage-users` playbook run before they will be able to access the servers.

### Rollback a release
If something goes wrong with a new release, you can rollback to the previous release by logging in to the server as `deploy` user into the `build/oceanconnect/` directory and run the following:
1. `mix deploy.local.rollback`
2. `sudo systemctl restart oceanconnect`

This will change the link of the current release back to the previous and restart the application to use it.

### Clearing old releases
If something goes wrong with deploying a release, 9 times out of 10 it's because that particular environment is out storage space for new releases.
You can find all the previous and current releases in `/opt/ocm/oceanconnect/releases`. When removing them, be careful not to delete the most recent release.

### Adding new servers
The `ansible/inventory/hosts` file lists out the hostnames/ips of servers that will be managed by Ansible using an INI format. These servers are sorted into _groups_ that Ansible can reference.

We currently have two primary groups set up: `staging`, and `production`. Additionally, `web-servers`, `build-servers`, and `db-servers` are also set up with both the staging and production servers for a semantic representation of our infrastructure.

The only required groups are `[py3-hosts]` and `[py3-hosts:vars]`. Most modern OSs have Python 3 installed by default, but Ansible defaults to Python 2. These groups tell Ansible to use Python 3 on those servers. Other groupings are up to you.

### Provisioning new servers
Install Ansible dependencies:

```
./ansible/ansible-galaxy install -r install_roles.yml
```

Ansible should make this fairly easy. If you've added the host names to `./ansible/inventory/hosts`, setup should be as simple as:

```bash
ansible-playbook -u root -v -l <server-group> playbooks/setup-web.yml -D
ansible-playbook -u root -v -l <server-group> playbooks/deploy-app.yml --skip-tags deploy -D
ansible-playbook -u root -v -l <server-group> playbooks/config-web.yml -D
ansible-playbook -u root -v -l <server-group> playbooks/setup-build.yml -D
ansible-playbook -u root -v -l <server-group> playbooks/setup-db.yml -D
ansible-playbook -u root -v -l <server-group> playbooks/config-build.yml -D
ansible-playbook -u root -v -l letsencrypt playbooks/letsencrypt.yml -D
```

Here, `<server-group>` is a host group defined in `./ansible/inventory/hosts`. You can also specify individual servers for more control/avoiding taking down other nodes.

Alternatively, since we mainly run all components (web, build, and db) on a single server, you can make a new host group for your servers and provision them that way. For example, a `demo-servers` group could list the hosts for a demo instance of the app.

One thing to note with this set of commands is that each server will be provisioned as the database, build server, _and_ application server all together. You can use different `hosts` file groups for each playbook to separate these components as needed. _Note: the `config` and `setup` steps for each type (web, build, db) must still be done on the same servers._

### Using an external database
If you have an external database setup to use, you can skip the `setup-db` playbook. This will avoid installing postgres and creating a database on the server.

Then, after provisioning the server the rest of the way, edit the `config/prod.secret.exs` file under the build directory (`~deploy/build/oceanconnect`) with your database's connection information.

### Restoring database from backup
**Create backup**
Save the database with `pg_dump -Ft -U <user name> <database name> > <backup tar file>` (eg: `pg_dump -Ft -U oceanconnect oceanconnect_prod > 2020_02_05_oceanconnect_staging.tar`).
**Note**: If the copy is on the server, you can copy it locally with `scp <user>@<server>:<path to file>/<tar file name> <local storage dir>` (eg: `scp root@206.189.247.123:~/2020_02_05_oceanconnect_staging.tar ~/Downloads/`).

**Restore from backup**
`pg_restore -Ft -c -U <database user> -d <database name> <path to pg_dump tar file>`
(eg: `pg_restore -Ft -c -U oceanconnect -d oceanconnect_dev ~/Desktop/2019-02-26-oceanconnect_staging.tar`)
Use the database password found in the dev.secret.exs or prod.secret.exs file. You may see 5 groupings of messages that
mention ERROR for query execution, which is normal.

### Setting hostname
In order for `*_url` helpers to work properly, Phoenix needs to be configured with the hostname that the site lives at. By default, Ansible will set this up as `localhost`, which is obviously not correct for remote servers. Since this is generally a per-server configuration, it has not been added as a configurable option there.

Instead, you'll need to log in to the new server as the `deploy` user and edit the `config/prod.secret.exs` file manually to set the `url.host` value to whatever domain name the deployment lives on:

```bash
ssh -A deploy@auctionstaging.oceanconnectmarine.com
cd ~/build/oceanconnect
cat config/prod.exs
# Copy the `OceanconnectWeb.Endpoint` configuration block
nano config/prod.secret.exs
# Paste the `Endpoint` config and replace the `System.get_env("APP_HOST")` with the proper domain name.
```

### SSH errors
If you get an error while running `setup-build.yml` about cloning the repository, make sure that your SSH key tied to your GitHub account is addded to the active SSH keyring running on your computer. You can check this with `ssh-add -l`. If it is not listed there, add it with `ssh-add -k <key_path>`.

```bash
ssh-add -l
ssh-add -k ~/.ssh/some_key
```


### Updating user lists
If new users join the project or old users need to be removed, you can run the `manage-users` playbook to update them on all relevant servers.

```bash
ansible-playbook -u root -v -l build-servers playbooks/manage-users.yml -D
```

It is safe to run this while the server is running and will not restart the application.

## Observing the Application
Get the port numbers for the running erlang processes by SSHing into the server as the `deploy` user and running `epmd -names`. If `epmd` is not available, reshim with asdf.

```bash
# If the `epmd` command is not found
cd ~/build/oceanconnect
asdf reshim erlang

epmd -names
```

Copy the port numbers from that command, then open up an ssh connection as the deploy user with those ports forwarded:

```bash
# Sample port numbers replaced here. 4369 is consistent, the other number is likely to change
ssh -L 4369:localhost:4369 -L 40497:localhost:40497 deploy@oceanconnect
```

Ansible creates a `~/.erlang.cookie` file under the application user (`ocm` for our deployments). SSH in as that user and copy the content of that file as your ssh cookie.

```bash
ssh -A ocm@server-name
cat ~/.erlang.cookie
```

Start a local observer instance with the erlang cookie of the target server:

```bash
erl -name debug@127.0.0.1 -setcookie <erlang_cookie> -hidden -run observer
```

From there, you should be able to connect to the remote node under the Nodes menu in the toolbar.
