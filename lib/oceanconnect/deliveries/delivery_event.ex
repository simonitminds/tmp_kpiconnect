defmodule Oceanconnect.Deliveries.DeliveryEvent do
  import Oceanconnect.Deliveries.Guards

  alias Oceanconnect.Delivers.QuantityClaim

  defstruct id: nil,
            type: nil,
            auction_id: nil,
            claim_id: nil,
            data: nil,
            time_entered: nil

  def claim_created(%struct{id: claim_id} = claim) when is_claim(struct) do
    %__MODULE__{
      id: UUID.uuid4(:hex),
      type: :claim_created,
      claim_id: claim_id,
      data: %{claim: claim},
      time_entered: DateTime.utc_now()
    }
  end
end
