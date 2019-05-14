defmodule Oceanconnect.Deliveries.DeliveryEvent do
  alias Oceanconnect.Deliveries.Claim

  defstruct id: nil,
            type: nil,
            auction_id: nil,
            claim_id: nil,
            data: nil,
            time_entered: nil

  def claim_created(%Claim{id: claim_id} = claim) do
    %__MODULE__{
      id: UUID.uuid4(:hex),
      type: :claim_created,
      claim_id: claim_id,
      data: %{claim: claim},
      time_entered: DateTime.utc_now()
    }
  end
end
