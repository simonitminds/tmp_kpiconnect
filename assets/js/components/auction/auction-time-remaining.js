import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { formatTimeRemaining, formatTimeRemainingColor } from '../../utilities';

const AuctionTimeRemaining = ({auctionPayload, auctionTimer, time}) => {
  const auctionStatus = _.get(auctionPayload, 'state.status');
  const cardDateFormat = (time) => { return moment(time).format("DD MMM YYYY, k:mm"); };

  if (auctionStatus == "open" || auctionStatus == "decision") {
    return (
      <span className={`auction-card__time-remaining auction-card__time-remaining--${formatTimeRemainingColor(auctionStatus, auctionTimer)}`}>
        <span className="icon has-margin-right-xs"><i className="far fa-clock"></i></span>
        <span
          className="qa-auction-time_remaining"
          id="time-remaining"
        >
          {formatTimeRemaining(auctionStatus, auctionTimer, "index")}
        </span>
      </span>
    );
  } else if (auctionStatus == "draft") {
    return (
      <span className="auction-card__time-remaining auction-card__time-remaining--inactive">
        <span className="icon has-margin-right-xs"><i className="far fa-clock"></i></span>
        Not Scheduled
      </span>
    );
  } else {
    return (
      <span className={`auction-card__time-remaining auction-card__time-remaining--${formatTimeRemainingColor(auctionStatus, auctionTimer)}`}>
        <span className="icon has-margin-right-xs"><i className="far fa-clock"></i></span>
        {cardDateFormat(_.get(auctionPayload, 'auction.auction_started'))}
      </span>
    );
  }
};

export default AuctionTimeRemaining;
