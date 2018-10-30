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
    belongs_to(:recipient_company, Oceanconnect.Accounts.Company)

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :has_been_seen])
    |> validate_required([:content, :has_been_seen])
  end

  def by_auction(auction_id) do
    from(
      m in Message,
      where: m.auction_id == ^auction_id
    )
  end
  def includes_author_company(query \\ Message, company_id) do
    from(
      q in query,
      or_where: q.author_company_id == ^company_id
    )
  end
  def includes_recipient_company(query \\ Message, company_id) do
    from(
      q in query,
      or_where: q.recipient_company_id == ^company_id
    )
  end
end
