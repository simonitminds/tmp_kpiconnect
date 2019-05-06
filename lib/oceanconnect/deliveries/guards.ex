defmodule Oceanconnect.Deliveries.Guards do
  alias Oceanconnect.Deliveries.QuantityClaim

  defguard is_claim(type) when type in [QuantityClaim]
end
