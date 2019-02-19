import _ from 'lodash';
import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

const SuppliersParticipating = ({auctionPayload}) => {
  const participations = _.get(auctionPayload, 'participations');
  const participationCounts = _.countBy(participations, _.identity);
  const {"yes": rsvpYesCount, "no": rsvpNoCount, "maybe": rsvpMaybeCount, null: rsvpNoResponseCount} = participationCounts;
  return (
    <React.Fragment>
      <div>Suppliers Participating</div>
      <div className="card-content__rsvp qa-auction-suppliers">
        <span className="icon has-text-success has-margin-right-xs"><FontAwesomeIcon icon="check-circle" /></span>{rsvpYesCount || "0"}&nbsp;
        <span className="icon has-text-warning has-margin-right-xs"><FontAwesomeIcon icon="adjust" /></span>{rsvpMaybeCount || "0"}&nbsp;
        <span className="icon has-text-danger has-margin-right-xs"><FontAwesomeIcon icon="times-circle" /></span>{rsvpNoCount || "0"}&nbsp;
        <span className="icon has-text-dark has-margin-right-xs"><FontAwesomeIcon icon="question-circle" /></span>{rsvpNoResponseCount || "0"}&nbsp;
      </div>
    </React.Fragment>
  )
}

export default SuppliersParticipating;
