defmodule Oceanconnect.Messages do
  @moduledoc """
  The Messages context.
  """

  import Ecto.Query, warn: false
  alias Oceanconnect.Repo

  alias Oceanconnect.Messages.Message

  @doc """
  Returns the list of messages.

  ## Examples

      iex> list_messages()
      [%Message{}, ...]

  """
  def list_messages do
    Repo.all(Message)
  end

  def list_auction_messages_for_company(auction_id, company_id) do
    auction_id
    |> Message.auction_messages_for_company(company_id)
    |> Repo.all()
  end

  def preload_messages(messages),
    do: Repo.preload(messages, [:author, :author_company, :impersonator, :recipient_company])

  def messages_by_thread(%{id: auction_id, buyer_id: buyer_id}) do
    auction_id
    |> list_auction_messages_for_company(buyer_id)
    |> preload_messages()
    |> Enum.group_by(fn message ->
      cond do
        buyer_id == message.author_company_id -> message.recipient_company
        buyer_id == message.recipient_company_id -> message.author_company
        true -> nil
      end
    end)
  end

  @doc """
  Gets a single message.

  Raises `Ecto.NoResultsError` if the Message does not exist.

  ## Examples

      iex> get_message!(123)
      %Message{}

      iex> get_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_message!(id), do: Repo.get!(Message, id)

  @doc """
  Creates a message.

  ## Examples

      iex> create_message(%{field: value})
      {:ok, %Message{}}

      iex> create_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a message.

  ## Examples

      iex> update_message(message, %{field: new_value})
      {:ok, %Message{}}

      iex> update_message(message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_message(%Message{} = message, attrs) do
    message
    |> Message.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Message.

  ## Examples

      iex> delete_message(message)
      {:ok, %Message{}}

      iex> delete_message(message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking message changes.

  ## Examples

      iex> change_message(message)
      %Ecto.Changeset{source: %Message{}}

  """
  def change_message(%Message{} = message) do
    Message.changeset(message, %{})
  end

  def get_related_company_ids(%Message{} = message), do: message.recipient_company_id
  def get_related_company_ids(_), do: nil
end
