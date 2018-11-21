import _ from 'lodash';
import React from 'react';

const MessagesAuctionHeader = ({payload, onSelect}) => {
  return (
    <div
        className={`qa-auction-${payload.auction_id}-message-payloads ${payload.unseen_messages ? "with-unseen" : ""}`}
        onClick={() => onSelect && onSelect(payload.auction_id)}>
      { onSelect &&
        <i className="fas fa-angle-right has-padding-right-nudge"></i>
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
        <span className="messaging__notifications qa-messages-unseen-count">{payload.unseen_messages}</span>
      }
    </div>
  );
}

export default MessagesAuctionHeader;
