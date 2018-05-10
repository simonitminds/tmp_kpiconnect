import React from 'react';
import _ from 'lodash';
import {
  convertToMinutes,
  formatUTCDateTime,
  formatTimeRemaining,
  formatTimeRemainingMobile,
  formatTimeRemainingColor
} from '../../utilities';
import ChannelConnectionStatus from './channel-connection-status';
import MediaQuery from 'react-responsive';

const AuctionHeader = ({auctionPayload, timeRemaining, connection}) => {
  const auction = _.get(auctionPayload, 'auction');
  const auctionStatus = _.get(auctionPayload, 'state.status');

  return(
    <div className="auction-app__header">
      <section className="auction-page">
        <div className="container">
          <div className="has-margin-top-lg">
            <div className="auction-header">
              <div className="columns has-margin-bottom-none">
                <div className="column">
                  <div className={`auction-header__status auction-header__status--${auctionStatus} tag is-rounded qa-auction-status`} id="time-remaining">
                    {auctionStatus}
                  </div>
                  <MediaQuery query="(max-width: 768px)">
                    <div className="auction-header__timer auction-header__timer--mobile has-text-left-mobile">
                      <ChannelConnectionStatus connection={connection} />
                      <div className={`auction-timer auction-timer--mobile auction-timer--${formatTimeRemainingColor(auctionStatus, timeRemaining)}`}>
                        <span className="qa-auction-time_remaining" id="time-remaining">
                          {formatTimeRemainingMobile(auctionStatus, timeRemaining, "show")}
                        </span>
                      </div>
                    </div>
                  </MediaQuery>

                  <h1 className="auction-header__vessel title has-text-weight-bold qa-auction-vessel">
                    {auction.vessel.name} <span className="auction-header__vessel__imo">({auction.vessel.imo})</span>
                    <span className="auction-header__company">{auction.buyer.name}</span>
                  </h1>
                  <div className="auction-header__ports--mobile is-hidden-desktop">
                    <span className="qa-auction-port has-text-weight-bold">{auction.port.name}</span>
                    <span className="has-text-weight-normal is-inline-block has-padding-left-sm"> (ETA {formatUTCDateTime(auction.eta)})</span>
                  </div>
                </div>
                <div className={`column ${auctionStatus != 'pending'? 'is-hidden-touch' : ''}`}>
                  <MediaQuery query="(min-width: 769px)">
                    <div className="auction-header__timer has-text-left-mobile">
                      <ChannelConnectionStatus connection={connection} />
                      <div className={`auction-timer auction-timer--${formatTimeRemainingColor(auctionStatus, timeRemaining)}`}>
                        <span className="qa-auction-time_remaining" id="time-remaining">
                          {formatTimeRemaining(auctionStatus, timeRemaining, "show")}
                        </span>
                      </div>
                    </div>
                  </MediaQuery>

                  <div className={`auction-header__start-time has-text-left-mobile ${auctionStatus != 'pending' ? 'is-hidden-touch' : ''}`}>
                    <span className="has-text-weight-bold is-uppercase">Start time</span> {formatUTCDateTime(auction.auction_start)}
                  </div>
                  <div className={`auction-header__duration has-text-left-mobile ${auctionStatus != 'pending' ? 'is-hidden-touch' : ''}`}>
                    <span className="has-text-weight-bold is-uppercase">Decision Period</span> {convertToMinutes(auction.decision_duration)} minutes
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
      <section className="auction-page auction-page--gray is-hidden-mobile">
        <div className="container">
          <div className="auction-header__ports has-text-weight-bold">
            <span className="qa-auction-port">{auction.port.name}</span>
            <span className="has-text-weight-normal is-inline-block has-padding-left-sm"> ETA {formatUTCDateTime(auction.eta)} &ndash; ETD {formatUTCDateTime(auction.etd)}</span>
          </div>
        </div>
      </section>
    </div>
  );
};

export default AuctionHeader;
