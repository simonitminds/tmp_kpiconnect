import React from 'react';
import _ from 'lodash';

const AuctionInvitation = ({auctionPayload, supplierId}) => {
  const {auction, participations} = auctionPayload
  const suppliersParticipationStatus = participations[supplierId]

  return(
    <div className="auction-invitation auction-invitation--large qa-auction-invitation-controls">
      <div className="auction-invitation__status box box--bordered-left">
        <h3 className="auction-invitation__status__copy">Do you intend to participate in the auction?</h3>
        <div className="field has-addons has-margin-right-md">
          <p className="control">
            <a className="button is-success" data-selected={suppliersParticipationStatus == "yes"} href={`/auctions/${auction.id}/rsvp?response=yes`}>
              <span>Accept</span>
            </a>
          </p>
          <p className="control">
            <a className="button is-danger" data-selected={suppliersParticipationStatus == "no"} href={`/auctions/${auction.id}/rsvp?response=no`}>
              <span>Decline</span>
            </a>
          </p>
          <p className="control">
            <a className="button is-gray-3" data-selected={suppliersParticipationStatus == "maybe"} href={`/auctions/${auction.id}/rsvp?response=maybe`}>
              <span>Maybe</span>
            </a>
          </p>
        </div>
      </div>
      {/* <div className = "auction-invitation__status auction-invitation__status--accepted box" >
        <div className="auction-invitation__status__marker">
          <i className="fas fa-lg fa-check-circle"></i>
        </div>
        <h3 className="auction-invitation__status__copy">
          You are participating in this auction
        </h3>
        <span className="auction-invitation__status__edit icon">
          <i className="fas fa-lg fa-pencil-alt"></i>
        </span>
      </div>
      <div className = "auction-invitation__status auction-invitation__status--decline box" >
        <div className="auction-invitation__status__marker">
          <i className="fas fa-lg fa-times-circle"></i>
        </div>
        <h3 className="auction-invitation__status__copy">
          You are not participating in this auction
        </h3>
        <span className="auction-invitation__status__edit icon">
          <i className="fas fa-lg fa-pencil-alt"></i>
        </span>
      </div>
      <div className = "auction-invitation__status auction-invitation__status--maybe box" >
        <div className="auction-invitation__status__marker">
          <i className="fas fa-lg fa-adjust"></i>
        </div>
        <h3 className="auction-invitation__status__copy">
          You might participate in this auction
        </h3>
        <span className="auction-invitation__status__edit icon">
          <i className="fas fa-lg fa-pencil-alt"></i>
        </span>
      </div>
      <div className = "auction-invitation__status auction-invitation__status--unanswered box" >
        <div className="auction-invitation__status__marker">
          <i className="fas fa-lg fa-question-circle"></i>
        </div>
        <h3 className="auction-invitation__status__copy">
          You have not RSVPed to this auction
        </h3>
      </div>
      <div className = "auction-invitation__status auction-invitation__status--unanswered box" >
        <div className="auction-invitation__status__marker">
          <i className="fas fa-lg fa-question-circle"></i>
        </div>
        <h3 className="auction-invitation__status__copy has-margin-top-xs">Change RSVP</h3>
        <div className="auction-invitation__status__button field has-addons has-margin-right-md">
          <div className="control">
            <div className="select">
              <select>
                <option disabled="disabled" value="">
                  Change Status
                </option>
                <option>Participating</option>
                <option>May Participate</option>
                <option>Not Participating</option>
              </select>
            </div>
          </div>
          <p className="control">
            <a className="button is-primary">
              <i className="fas fa-md fa-check"></i>
            </a>
          </p>
        </div>
      </div> */}
    </div>
  );
};

export default AuctionInvitation;
