import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { formatTimeRemaining, formatTimeRemainingColor } from '../../utilities';

const AuctionTimeRemaining = ({auctionPayload, auctionTimer}) => {
  const auctionStatus = _.get(auctionPayload, 'status');
  const auctionStartTime = _.get(auctionPayload, 'auction.scheduled_start');
  const auctionEndTime = _.get(auctionPayload, 'auction.auction_ended');
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
  } else if (auctionStatus == "pending") {
    return (
      <span className="auction-card__time-remaining auction-card__time-remaining--inactive">
        <span className="icon has-margin-right-xs"><i className="far fa-clock"></i></span>
        {cardDateFormat(auctionStartTime)}
      </span>
    );
  } else if (auctionStatus == "canceled") {
    return (
      <span className="auction-card__time-remaining auction-card__time-remaining--inactive">
        <span className="icon has-margin-right-xs"><i className="far fa-clock"></i></span>
        {cardDateFormat(auctionStartTime)}
      </span>
    );
  } else {
    return (
      <span className={`auction-card__time-remaining auction-card__time-remaining--${formatTimeRemainingColor(auctionStatus, auctionTimer)}`}>
        <span className="icon has-margin-right-xs"><i className="far fa-clock"></i></span>
        {cardDateFormat(auctionEndTime)}
      </span>
    );
  }
};

export default AuctionTimeRemaining;
