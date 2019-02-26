import React from 'react';
import _ from 'lodash';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import {
  convertToMinutes,
  etaAndEtdForAuction,
  formatUTCDateTime,
  formatMonthYear
} from '../../../../utilities';
import MediaQuery from 'react-responsive';
import AuctionHeaderTimers from '../../common/show/auction-header-timers';
import AuctionTitle from '../../common/auction-title';


const Header = ({auctionPayload, connection}) => {
  const auction = _.get(auctionPayload, 'auction');
  const auctionType = _.get(auction, 'type');
  const auctionStatus = _.get(auctionPayload, 'status');

  const portName = _.get(auction, 'port.name');
  const vessels = _.get(auction, 'vessels');
  const startDate = _.get(auction, 'start_date');
  const endDate = _.get(auction, 'end_date');


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
                  <h1 className="auction-header__vessel title">
                    <AuctionTitle auction={auction} />
                    <span className="auction-header__company">{auction.buyer.name}</span>
                  </h1>
                </div>
                <div className={`column ${auctionStatus != 'pending'? 'is-hidden-mobile' : ''}`}>
                  <MediaQuery query="(min-width: 769px)">
                    <AuctionHeaderTimers auctionPayload={auctionPayload} connection={connection} isMobile={false} />
                  </MediaQuery>

                  <div className={`auction-header__start-time has-text-left-mobile ${auctionStatus != 'pending' ? 'is-hidden-mobile' : ''}`}>
                    <span className="has-text-weight-bold is-uppercase">Start time</span> {displayAuctionStartTime()}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
      <section className="auction-page auction-page--gray is-hidden-mobile">
        <div className="container">
          <div className="auction-header__ports">
            <div className="qa-auction-vessels is-block">
              { _.map(vessels, (vessel) => {
                  return(
                    <span key={vessel.name} className={`qa-auction-vessel-${vessel.id} has-margin-right-sm`}>
                      <strong>{vessel.name}</strong> ({vessel.imo})
                    </span>
                  );
                })
              }
            </div>
            <div className="is-block">
              <strong>{_.startCase(auctionType)} Term</strong> ({formatMonthYear(startDate)} &ndash; {formatMonthYear(endDate)})
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};

export default Header;
