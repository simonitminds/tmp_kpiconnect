# Ocean

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


### Git Process for Branch Merging

**Use Pull Requests for new changes. Master has been protected from pushes.**

* Run `git checkout master`
* Run `git pull --rebase`
* Run `git checkout [branch]`
* Run `git rebase master`
* Confirm all tests still pass with `mix test`
* Run `git push -f`
* Run `git checkout master`
* Run `git merge --no-ff [branch]`
* Run `git push origin master`


# OCM Notes
```
       __ Users _______
      /    |           \
Buyers     Suppliers       Admin
   |          |   \
 Vessels   Ports   Barges
   |        /
Auction-----
```


### Ports
-  have an associated Timezone for ETD ETA of Ship Arrival on Auction


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


# Releasing

We're using Ansible to manage server provisioning and deployments. For the most part, doing a new deploy involves:

1. Log into the build server with `ssh -A deploy@oceanconnect`
2. `cd ~/build/oceanconnect/`
3. Run `./scripts/build-release.sh` to build the new release binary
4. Run any necessary migrations with `./scripts/db-migrate.sh`
5. Deploy with `./scripts/deploy-local.sh`

New users will need to add their account information to `ansible/inventory/group_vars/all/users.yml` and have the `manage-users` playbook run before they will be able to access the servers.

# Clearing old releases

If something goes wrong with deploying a release, 9 times out of 10 it's because that particular environment is out storage space for new releases.

You can find all the previous and current releases in `/opt/ocm/oceanconnect/releases`. When removing them, be careful not to delete the most recent release.


### Setting up `yarn`

This project now depends on `yarn` for managing dependencies and building assets with `parcel`. After all the ansible setup has been completed, you'll need to install `yarn` using the installation method suggested for the server's OS here: https://yarnpkg.com/en/docs/install#debian-stable.

Without this, you'll get an error that `yarn` could not be found and `./scripts/build-release.sh` will fail.


### Adding new servers

The `ansible/inventory/hosts` file lists out the hostnames/ips of servers that will be managed by Ansible using an INI format. These servers are sorted into _groups_ that Ansible can reference.

We currently have two primary groups set up: `staging`, and `production`. Additionally, `web-servers`, `build-servers`, and `db-servers` are also set up with both the staging and production servers for a semantic representation of our infrastructure.

The only required groups are `[py3-hosts]` and `[py3-hosts:vars]`. Most modern OSs have Python 3 installed by default, but Ansible defaults to Python 2. These groups tell Ansible to use Python 3 on those servers. Other groupings are up to you.


### Provisioning new servers

Ansible should make this fairly easy. If you've added the host names to `./ansible/inventory/hosts`, setup should be as simple as:

```bash
ansible-playbook -u root -v -l <server-group> playbooks/setup-web.yml -D
ansible-playbook -u root -v -l <server-group> playbooks/deploy-app.yml --skip-tags deploy -D
ansible-playbook -u root -v -l <server-group> playbooks/config-web.yml -D
ansible-playbook -u root -v -l <server-group> playbooks/setup-build.yml -D
ansible-playbook -u root -v -l <server-group> playbooks/setup-db.yml -D
ansible-playbook -u root -v -l <server-group> playbooks/config-build.yml -D
```

Here, `<server-group>` is a host group defined in `./ansible/inventory/hosts`. You can also specify individual servers for more control/avoiding taking down other nodes.

Alternatively, since we mainly run all components (web, build, and db) on a single server, you can make a new host group for your servers and provision them that way. For example, a `demo-servers` group could list the hosts for a demo instance of the app.

One thing to note with this set of commands is that each server will be provisioned as the database, build server, _and_ application server all together. You can use different `hosts` file groups for each playbook to separate these components as needed. _Note: the `config` and `setup` steps for each type (web, build, db) must still be done on the same servers._


### Using an external database

If you have an external database setup to use, you can skip the `setup-db` playbook. This will avoid installing postgres and creating a database on the server.

Then, after provisioning the server the rest of the way, edit the `config/prod.secret.exs` file under the build directory (`~deploy/build/oceanconnect`) with your database's connection information.


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
