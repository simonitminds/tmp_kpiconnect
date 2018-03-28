import React from 'react';
import _ from 'lodash';
import {
  convertToMinutes,
  formatUTCDateTime,
  formatTimeRemaining,
  formatTimeRemainingColor
} from '../../utilities';

const AuctionHeader = ({auctionPayload, timeRemaining}) => {
  const auction = _.get(auctionPayload, 'auction');
  const auctionStatus = _.get(auctionPayload, 'state.status');

  return(
    <div>
      <section className="auction-page">
        <div className="container">
          <div className="has-margin-top-lg">
            <div className="auction-header">
              <div className="columns has-margin-bottom-none">
                <div className="column">
                  <div className={`auction-header__status auction-header__status--${auctionStatus} tag is-rounded qa-auction-status`} id="time-remaining">
                    {auctionStatus}
                  </div>
                  <div className="auction-header__po is-uppercase">
                    Auction {auction.po}
                  </div>
                  <h1 className="auction-header__vessel title has-text-weight-bold qa-auction-vessel">
                    {auction.vessel.name} <span className="auction-header__vessel__imo">({auction.vessel.imo})</span>
                  </h1>
                </div>
                <div className="column">
                  <div className="auction-header__timer has-text-left-mobile">
                    <div className={`auction-timer auction-timer--${formatTimeRemainingColor(auctionStatus, timeRemaining)}`}>
                      <span className="qa-auction-time_remaining" id="time-remaining">
                        {formatTimeRemaining(auctionStatus, timeRemaining, "show")}
                      </span>
                    </div>
                  </div>
                  <div className="auction-header__start-time has-text-left-mobile">
                    <span className="has-text-weight-bold is-uppercase">Started at</span> {formatUTCDateTime(auction.auction_start)} GMT
                  </div>
                  <div className="auction-header__duration has-text-left-mobile">
                    <span className="has-text-weight-bold is-uppercase">Decision Period</span> {convertToMinutes(auction.decision_duration)} minutes
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
      <section className="auction-page auction-page--gray">
        <div className="container">
          <div className="auction-header__ports has-text-weight-bold">
            <span className="qa-auction-port">{auction.port.name}</span>
            <span className="has-text-weight-normal is-inline-block has-padding-left-sm"> ETA {formatUTCDateTime(auction.eta)} GMT &ndash; ETD {formatUTCDateTime(auction.etd)} GMT</span>
          </div>
        </div>
      </section>
    </div>
  );
};

export default AuctionHeader;
