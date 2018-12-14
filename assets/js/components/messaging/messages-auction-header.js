import _ from 'lodash';
import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

const MessagesAuctionHeader = ({payload, onSelect}) => {
  return (
    <div
        className={`qa-auction-${payload.auction_id}-message-payloads ${payload.unseen_messages ? "with-unseen" : ""}`}
        onClick={() => onSelect && onSelect(payload.auction_id)}>
      { onSelect &&
        <FontAwesomeIcon icon="angle-right" className="has-padding-right-nudge" />
      }

      <div className={`auction-status auction-status--${payload.status}`}>
        {payload.status}
      </div>
      {
        _.map(payload.vessels, (vessel) => {
          return(
            <span key={vessel.id}><span className="has-text-gray-3">{payload.auction_id}</span> {vessel.name} <span className="has-text-gray-3">({vessel.imo})</span></span>
          );
        })
      }
      { payload.unseen_messages > 0 &&
        <span className="messaging__notifications qa-messages-unseen-count"><FontAwesomeIcon icon="envelope" className="has-margin-right-xs" /> {payload.unseen_messages}</span>
      }
    </div>
  );
}

export default MessagesAuctionHeader;
