import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { cardDateFormat, timeRemainingCountdown } from '../../utilities';
import ServerDate from '../../serverdate';
import CollapsibleSection from './common/collapsible-section';
import ChannelConnectionStatus from './common/channel-connection-status';
import MediaQuery from 'react-responsive';
import { componentsForAuction } from './common';

export default class AuctionsIndex extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      timeRemaining: {},
      serverTime: moment().utc()
    };
  }

  render() {
    const connection = this.props.connection;
    const currentUserIsAdmin = window.isAdmin && !window.isImpersonating;
    const currentUserIsBuyer = (auction) => { return((parseInt(this.props.currentUserCompanyId) === auction.buyer.id) || currentUserIsAdmin); };

    const filteredAuctionPayloads = (status) => {
      return _.filter(this.props.auctionPayloads, (auctionPayload) => {
          return(auctionPayload.status === status);
        });
    };

    const chronologicalAuctionPayloads = (auctionPayloads, status) => {
      let sortField = 'auction_started';
      switch(status) {
        case 'pending':
          sortField = 'scheduled_start';
          break;
        case 'open':
        case 'decision':
          sortField = 'auction_started';
          break;
        default:
          sortField = 'id';
          break;
      }
      return _.orderBy(auctionPayloads, [
          auctionPayload => _.get(auctionPayload.auction, sortField),
          auctionPayload => auctionPayload.auction.id
        ],
        ['desc', 'desc']
      );
    };

    const filteredAuctionsDisplay = (status) => {
      const filteredPayloads = chronologicalAuctionPayloads(filteredAuctionPayloads(status), status);
      if(_.isEmpty(filteredPayloads)) {
        return(
          <div className="empty-list">
            <em>You have no {status} auctions</em>
          </div>);
      } else if(status == "draft") {
        return(
          <div className="columns is-multiline">
            { _.map(filteredPayloads, (auctionPayload) => {
              const auctionType = _.get(auctionPayload, 'auction.type');
              const { BuyerDraftCard } = componentsForAuction(auctionType);
              if (currentUserIsBuyer(auctionPayload.auction)) {
                return <BuyerDraftCard
                  key={auctionPayload.auction.id}
                  auctionPayload={auctionPayload}
                  timeRemaining={this.state.timeRemaining[auctionPayload.auction.id]}
                />;
              }
            }) }
          </div>);
      } else {
        return(
          <div className="columns is-multiline">
            { _.map(filteredPayloads, (auctionPayload) => {
              const auctionType = _.get(auctionPayload, 'auction.type');
              const { BuyerCard, SupplierCard } = componentsForAuction(auctionType);
              if (currentUserIsBuyer(auctionPayload.auction)) {
                return <BuyerCard
                  key={auctionPayload.auction.id}
                  auctionPayload={auctionPayload}
                  timeRemaining={this.state.timeRemaining[auctionPayload.auction.id]}
                />;
              } else {
                return <SupplierCard
                  key={auctionPayload.auction.id}
                  auctionPayload={auctionPayload}
                  timeRemaining={this.state.timeRemaining[auctionPayload.auction.id]}
                  connection={connection}
                  currentUserCompanyId={this.props.currentUserCompanyId}
                />;
              }
            }) }
          </div>);
      }
    };
    const filteredAuctionsCount = (status) => {
      return filteredAuctionPayloads(status).length;
    };

    return (
      <div className="auction-app">
        <div className="auction-app__header auction-app__header--list container is-fullhd">
          <div className="content is-clearfix">
            <MediaQuery query="(max-width: 599px)">
              <div>
                <div className="auction-list__time-box">
                  <ChannelConnectionStatus connection={connection} />
                  <div className="auction-list__timer">
                    <FontAwesomeIcon icon={["far", "clock"]} className="has-margin-right-xs" />
                    <span className="auction-list__timer__clock" id="gmt-time" >
                      {this.state.serverTime.format("DD MMM YYYY, k:mm:ss")}
                    </span>&nbsp;GMT
                  </div>
                </div>
                <a href="/auctions/new" className="auction-list__new-auction button is-link is-pulled-right is-small has-margin-bottom-md">
                  New Auction
                </a>
                <a href="/historical_auctions" className="auction-list__new-auction button is-link is-pulled-right is-small has-margin-bottom-md">
                  <span>Historical Auctions</span>
                  <span className="icon"><i className="fas fa-arrow-right is-pulled-right"></i></span>
                </a>
              </div>
            </MediaQuery>
            <h1 className="title auction-list__title">Current Auctions</h1>
            <MediaQuery query="(min-width: 600px)">
              <div>
                <a href="/historical_auctions" className="button is-link is-pulled-right">
                  <span>Historical Auctions</span>
                  <span className="icon"><i className="fas fa-arrow-right is-pulled-right"></i></span>
                </a>
                <a href="/auctions/new" className="button is-link is-pulled-right has-margin-right-md">
                  New Auction
                </a>
                <div className="auction-list__time-box">
                  <ChannelConnectionStatus connection={connection} />
                  <div className="auction-list__timer">
                    <FontAwesomeIcon icon={["far", "clock"]} className="has-margin-right-xs" />
                    <span className="auction-list__timer__clock" id="gmt-time" >
                      {this.state.serverTime.format("DD MMM YYYY, k:mm:ss")}
                    </span>&nbsp;GMT
                  </div>
                    <i className="is-hidden-mobile">Server Time</i>
                </div>
              </div>
            </MediaQuery>
          </div>
        </div>
        <div className="auction-app__body">
          <CollapsibleSection
            trigger="Active Auctions"
            classParentString="qa-open-auctions-list auction-list"
            contentChildCount={filteredAuctionsCount("open")}
            open={filteredAuctionsCount("open") > 0}
            >
            { filteredAuctionsDisplay("open") }
          </CollapsibleSection>
          <CollapsibleSection
            trigger="Auctions In Decision"
            classParentString="qa-decision-auctions-list auction-list"
            contentChildCount={filteredAuctionsCount("decision")}
            open={filteredAuctionsCount("decision") > 0}
            >
            { filteredAuctionsDisplay("decision") }
          </CollapsibleSection>
          <CollapsibleSection
            trigger="Upcoming Auctions"
            classParentString="qa-pending-auctions-list auction-list"
            contentChildCount={filteredAuctionsCount("pending")}
            open={filteredAuctionsCount("pending") > 0}
            >
            { filteredAuctionsDisplay("pending") }
          </CollapsibleSection>
          <CollapsibleSection
            trigger="Unscheduled Auctions"
            classParentString="qa-draft-auctions-list auction-list"
            contentChildCount={filteredAuctionsCount("draft")}
            open={filteredAuctionsCount("draft") > 0}
            >
            { filteredAuctionsDisplay("draft") }
          </CollapsibleSection>
        </div>
      </div>
    );
  }
}
