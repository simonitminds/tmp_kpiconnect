import React from 'react';
import _ from 'lodash';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  convertToMinutes,
  etaAndEtdForAuction,
  formatUTCDateTime
} from '../../../../utilities';
import MediaQuery from 'react-responsive';
import AuctionHeaderTimers from '../../common/show/auction-header-timers';
import AuctionTitle from '../../common/auction-title';


const Header = ({auctionPayload, connection}) => {
  const auction = _.get(auctionPayload, 'auction');
  const auctionStatus = _.get(auctionPayload, 'status');
  const { eta, etd } = etaAndEtdForAuction(auction);

  const displayAuctionStartTime = () => {
    if (auctionStatus == 'pending') {
      return formatUTCDateTime(auction.scheduled_start);
    } else {
      return formatUTCDateTime(auction.auction_started);
    }
  }

  return(
    <div className="auction-app__header auction-app__header--show">
      <section className="auction-page">
        <div className="container">
          <div className="has-margin-top-lg">
            <div className="auction-header">
              <div className="columns has-margin-bottom-none">
                <div className="column">
                  <div className={`auction-status auction-status--${auctionStatus} tag is-rounded qa-auction-status`} id="time-remaining">
                    {auctionStatus}
                  </div>
                  <MediaQuery query="(max-width: 768px)">
                    <AuctionHeaderTimers auctionPayload={auctionPayload} connection={connection} isMobile={true} />
                  </MediaQuery>
                  <div className="qa-auction-vessels">
                    <h1 className="title auction-header__vessel has-text-weight-bold">
                      <AuctionTitle auction={auction} />
                      <span className="auction-header__company">{auction.buyer ? auction.buyer.name : 'Buyer Company Name'}</span>
                    </h1>
                  </div>
                  <div className="auction-header__ports--mobile">
                    <span className="qa-auction-port has-text-weight-bold">{auction.port.name}</span>
                    <span className="has-text-weight-normal is-inline-block has-padding-left-sm"> (ETA {formatUTCDateTime(eta)})</span>
                  </div>
                </div>
                <div className={`column ${auctionStatus != 'pending'? 'is-hidden-mobile' : ''}`}>
                  <MediaQuery query="(min-width: 769px)">
                    <AuctionHeaderTimers auctionPayload={auctionPayload} connection={connection} isMobile={false} />
                  </MediaQuery>

                  <div className={`auction-header__start-time has-text-left-mobile ${auctionStatus != 'pending' ? 'is-hidden-mobile' : ''}`}>
                    <span className="has-text-weight-bold is-uppercase">Start time</span> {displayAuctionStartTime()}
                  </div>
                  <div className={`auction-header__duration has-text-left-mobile ${auctionStatus != 'pending' ? 'is-hidden-mobile' : ''}`}>
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
            <span className="has-text-weight-normal is-inline-block has-padding-left-sm"> ETA {formatUTCDateTime(eta)} &ndash; ETD {formatUTCDateTime(etd)}</span>
          </div>
        </div>
      </section>
    </div>
  );
};

export default Header;
