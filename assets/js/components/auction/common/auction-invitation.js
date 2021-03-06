import React from 'react';
import _ from 'lodash';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

const AuctionInvitation = ({auctionPayload, supplierId}) => {
  const {auction, participations} = auctionPayload;
  const suppliersParticipationStatus = participations[supplierId];

  const supplierParticipationModifier = () => {
    switch (suppliersParticipationStatus) {
      case "yes":   return "auction-invitation__status--accepted";
      case "no":    return "auction-invitation__status--declined";
      case "maybe": return "auction-invitation__status--maybe";
      default:      return "auction-invitation__status--unanswered";
    }
  }

  const styleStatusContainer = () => {
    switch (suppliersParticipationStatus) {
      case "yes":
        return (
          <span className="auction-invitation__status__marker">
            <FontAwesomeIcon icon="check-circle" size="lg" />
          </span>
        );
      case "no":
        return (
          <span className="auction-invitation__status__marker">
            <FontAwesomeIcon icon="times-circle" size="lg" />
          </span>
        );
      case "maybe":
        return (
          <span className="auction-invitation__status__marker">
            <FontAwesomeIcon icon="adjust" size="lg" />
          </span>
        );
      default:
        return(
          <span className="auction-invitation__status__marker">
            <FontAwesomeIcon icon="question-circle" size="lg" />
          </span>
        );
    }
  };

  return(
    <div className="auction-invitation auction-invitation--large qa-auction-invitation-controls">
      <div className={`auction-invitation__status box ${supplierParticipationModifier()}`}>
        {styleStatusContainer()}
        <div className="auction-invitation__status__form">
          <h3 className="auction-invitation__status__copy">
            {styleStatusContainer()}
            <div className="qa-auction-supplier-participation">
              {suppliersParticipationStatus == "yes" && "You are participating in this auction"}
              {suppliersParticipationStatus == "no" && "You are not participating in this auction"}
              {suppliersParticipationStatus == "maybe" && "You might participate in this auction"}
              {!suppliersParticipationStatus && "Do you intend to participate in this auction?"}
            </div>
          </h3>
          <div className="field has-addons has-margin-right-md">
            <p className="control">
                <a className={`button is-success qa-auction-${auction.id}-rsvp-response qa-auction-${auction.id}-rsvp-response-yes`} data-selected={suppliersParticipationStatus == "yes"} href={`/auctions/${auction.id}/rsvp?response=yes`}>
                <span>Accept</span>
              </a>
            </p>
            <p className="control">
                <a className={`button is-danger qa-auction-${auction.id}-rsvp-response qa-auction-${auction.id}-rsvp-response-no`} data-selected={suppliersParticipationStatus == "no"} href={`/auctions/${auction.id}/rsvp?response=no`}>
                <span>Decline</span>
              </a>
            </p>
            <p className="control">
                <a className={`button button--borderless is-gray-3 qa-auction-${auction.id}-rsvp-response qa-auction-${auction.id}-rsvp-response-maybe`} data-selected={suppliersParticipationStatus == "maybe"} href={`/auctions/${auction.id}/rsvp?response=maybe`}>
                <span>Maybe</span>
              </a>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AuctionInvitation;
