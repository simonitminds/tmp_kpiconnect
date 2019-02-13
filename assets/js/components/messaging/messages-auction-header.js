import _ from 'lodash';
import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import AuctionTitle from '../auction/common/auction-title';

const MessagesAuctionHeader = ({payload, onSelect}) => {
  const {
    auction,
    auction_id,
    unseen_messages,
    status
  } = payload;

  return (
    <div
        className={`qa-auction-${auction_id}-message-payloads ${unseen_messages ? "with-unseen" : ""}`}
        onClick={() => onSelect && onSelect(auction_id)}>
      { onSelect &&
        <FontAwesomeIcon icon="angle-right" className="has-padding-right-nudge" />
      }

      <div className={`auction-status auction-status--${status}`}>
        {status}
      </div>
      <div>
        <AuctionTitle auction={auction} />
      </div>
      { unseen_messages > 0 &&
        <span className="messaging__notifications qa-messages-unseen-count"><FontAwesomeIcon icon="envelope" className="has-margin-right-xs" /> {unseen_messages}</span>
      }

    </div>
  );
}

export default MessagesAuctionHeader;
