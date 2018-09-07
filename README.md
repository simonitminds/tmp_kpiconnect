# Ocean

To start your Phoenix server:

* Install dependencies with `mix deps.get`
* Create and migrate your database with `mix ecto.create && mix ecto.migrate`
* Install Node.js dependencies with `cd assets && yarn install`
* Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

To run tests locally:

* Install Selenium with `brew install selenium-server-standalone`
* Install Chromedriver with  `brew install chromedriver`
* Start Selenium with `selenium-server`
* In another terminal window, run `mix test`

## Nanobox

We use Nanobox for deployments to Azure.

* Create an account and install nanobox: https://dashboard.nanobox.io/download
* Run `nanobox dns add local phoenix.local`
* Follow the recommended nanobox setup steps in your terminal
* Run `nanobox run`
* Run `mix deps.get`
* Run `cd assets && yarn install cd ../`
* Run `mix ecto.create`
* Run `mix phx.server`
* Go to `phoenix.local:4000` in the browser

### Seed data

* The seeds file will delete items in the database and seed new data
* Run `mix run priv/repo/seeds.exs`

### To run the "console" on Production follow these steps:

* Run `nanobox console web.main`
* Run `iex -S mix`
* Then do things

Nanobox article on phoenix and azure deploys:
https://content.nanobox.io/how-to-deploy-phoenix-applications-to-microsoft-azure-with-nanobox/#updatethedatabaseconnection

Nanobox guides: https://guides.nanobox.io/elixir/phoenix/existing-app/

### Git Process for Branch Merging

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

       __ Users _______
      /    |           \
Buyers     Suppliers       Admin
   |          |   \
 Vessels   Ports   Barges
   |        /
Auction-----


## Ports
-  have an associated Timezone for ETD ETA of Ship Arrival on Auction


# Clearing All Data
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

# Troubleshooting Production / Staging (Nanobox)

## Add your ssh key to nanobox and download the identity file / key from Nanobox
 - https://dashboard.nanobox.io/apps/8bc19967-0e9d-4303-91f6-67ea36f14923/security?ci=af0b01c6-391d-4b35-a8ae-07e88b2f7d4a

## Port Forward 19000 from the Docker host on Nanobox to your local host
 - `ssh nanobox@13.90.241.202 -R 172.17.0.1:4369:127.0.0.1:4369 -R 172.17.0.1:19000:127.0.0.1:19000 -N -i ../nanobox_private_key`

## Create a local node
 - `iex --name node@172.17.0.1  --cookie nanobox --erl "-kernel inet_dist_listen_min 19000 inet_dist_listen_max 19000" -S mix`

## Attach to the nanobox console
  - `nanbox console web.main`
  - `node-attach`
  - `Node.connect :'node@172.17.0.1'`

## From your Local node on your machine
 - `:observer.start`

## Select the web.main node from the node list in observer from the toolbar menu


## Releasing

We're using Ansible to manage server provisioning and deployments. For the most part, doing a new deploy involves:

1. Log into the build server with `ssh -A deploy@oceanconnect`
2. `cd ~/build/oceanconnect/`
3. Run `./scripts/build-release.sh` to build the new release binary
4. Deploy with `./scripts/deploy-local.sh`

New users will need to add their account information to `ansible/inventory/group_vars/all/users/yml` before they will be able to access the servers.
