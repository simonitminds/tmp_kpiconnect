defmodule Oceanconnect.Notifications do
  import Ecto.Query, warn: false
  import Oceanconnect.Auctions.Guards

  alias Oceanconnect.Notifications.Emails
  alias Oceanconnect.Deliveries.{Claim, ClaimResponse}

  alias Oceanconnect.Auctions.{AuctionEvent, AuctionFixture}

  def emails_for_event(
        %AuctionEvent{type: type},
        auction_state = %state_struct{auction_id: _auction_id}
      )
      when is_auction_state(state_struct) and
             type in [:auction_created, :auction_transitioned_from_draft_to_pending] do
    Emails.AuctionInvitation.generate(auction_state)
  end

  def emails_for_event(
        %AuctionEvent{type: :auction_closed},
        auction_state = %state_struct{auction_id: _auction_id}
      )
      when is_auction_state(state_struct) do
    Emails.AuctionClosed.generate(auction_state)
  end

  def emails_for_event(
        %AuctionEvent{type: :auction_rescheduled},
        auction_state = %state_struct{auction_id: _auction_id}
      )
      when is_auction_state(state_struct) do
    Emails.AuctionRescheduled.generate(auction_state)
  end

  def emails_for_event(
        %AuctionEvent{type: :upcoming_auction_notified},
        auction_state = %state_struct{auction_id: _auction_id}
      )
      when is_auction_state(state_struct) do
    Emails.AuctionStartingSoon.generate(auction_state)
  end

  def emails_for_event(
        %AuctionEvent{type: :auction_canceled},
        auction_state = %state_struct{auction_id: _auction_id}
      )
      when is_auction_state(state_struct) do
    Emails.AuctionCanceled.generate(auction_state)
  end

  def emails_for_event(
        %AuctionEvent{type: :claim_created},
        %Claim{} = claim
      ) do
    Emails.ClaimCreated.generate(claim)
  end

  def emails_for_event(
        %AuctionEvent{type: :claim_response_created},
        %ClaimResponse{} = response
      ) do
    Emails.ClaimResponseCreated.generate(response)
  end

  def emails_for_event(
        %AuctionEvent{type: :fixture_created},
        %AuctionFixture{} = fixture
      ) do
    Emails.FixtureCreated.generate(fixture)
  end

  def emails_for_event(
        %AuctionEvent{type: :fixture_delivered},
        %AuctionFixture{} = fixture
      ) do
    Emails.FixtureDelivered.generate(fixture)
  end

  def emails_for_event(
        %AuctionEvent{type: :fixture_updated, data: %{updated: changeset}},
        %AuctionFixture{} = fixture
      ) do
    Emails.FixtureUpdated.generate(fixture, changeset)
  end

  def emails_for_event(
        %AuctionEvent{type: :fixture_changes_proposed, data: %{changeset: changeset, user: user}},
        %AuctionFixture{} = fixture
      ) do
    Emails.FixtureChangesProposed.generate(fixture, changeset, user)
  end

  def emails_for_event(
        %AuctionEvent{type: _type},
        _auction_state
      ) do
    []
  end

  def emails_for_non_event(:delivered_coq_uploaded, auction_supplier_coq) do
    Emails.DeliveredCOQUploaded.generate(auction_supplier_coq)
  end

  def emails_for_non_event(:password_reset, %{user: user, token: token}) do
    Emails.PasswordReset.generate(user, token)
  end

  def emails_for_non_event(:two_factor_auth, %{user: user, one_time_pass: one_time_pass}) do
    Emails.TwoFactorAuth.generate(user, one_time_pass)
  end

  def emails_for_non_event(:user_interest, new_user_info) do
    Emails.UserInterest.generate(new_user_info)
  end
end
