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
      <div>
        <span className="has-text-gray-3 has-padding-right-xs">{payload.auction_id}</span>
      {
        _.map(payload.vessels, (vessel) => {
          return(
            <span key={vessel.id} className="messaging__vessel-name">{vessel.name} <span className="has-text-gray-3">({vessel.imo})</span></span>
          );
        })
      }
      </div>
      { payload.unseen_messages > 0 &&
        <span className="messaging__notifications qa-messages-unseen-count"><FontAwesomeIcon icon="envelope" className="has-margin-right-xs" /> {payload.unseen_messages}</span>
      }

    </div>
  );
}

export default MessagesAuctionHeader;
