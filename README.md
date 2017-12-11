# Ocean

To start your Phoenix server:

* Install dependencies with `mix deps.get`
* Create and migrate your database with `mix ecto.create && mix ecto.migrate`
* Install Node.js dependencies with `cd assets && yarn install`
* Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Nanobox

We use Nanobox for deployments to Azure

* Create an account and install nanobox: https://dashboard.nanobox.io/download
* Run `nanobox dns add local phoenix.local`
* Follow the recommended nanobox setup steps in your terminal
* Run `nanobox run`
* Run `mix deps.get`
* Run `cd assets && yarn install cd ../`
* Run `mix ecto.create`
* Run `mix phx.server`

Nanobox article on phoenix and azure deploys: https://content.nanobox.io/how-to-deploy-phoenix-applications-to-microsoft-azure-with-nanobox/#updatethedatabaseconnection
Nanobox guides: https://guides.nanobox.io/elixir/phoenix/existing-app/
