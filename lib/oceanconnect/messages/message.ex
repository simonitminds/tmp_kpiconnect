defmodule Oceanconnect.Messages.Message do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias __MODULE__

  schema "messages" do
    field(:content, :string)
    field(:has_been_seen, :boolean, default: false)
    belongs_to(:auction, Oceanconnect.Auctions.Auction)
    belongs_to(:author, Oceanconnect.Accounts.User)
    belongs_to(:author_company, Oceanconnect.Accounts.Company)
    belongs_to(:impersonator, Oceanconnect.Accounts.User)
    belongs_to(:recipient_company, Oceanconnect.Accounts.Company)

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [
      :author_id,
      :author_company_id,
      :auction_id,
      :content,
      :has_been_seen,
      :impersonator_id,
      :recipient_company_id
    ])
    |> validate_required([:content, :has_been_seen])
  end

  def auction_messages_for_company(auction_id, company_id) do
    Message
    |> where(
      [m],
      m.auction_id == ^auction_id and
        (m.author_company_id == ^company_id or m.recipient_company_id == ^company_id)
    )
    |> order_by(asc: :id)
  end
end
