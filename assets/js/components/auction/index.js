import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { timeRemainingCountdown } from '../../utilities';
import ServerDate from '../../serverdate';
import BuyerAuctionCard from './buyer-auction-card';
import SupplierAuctionCard from './supplier-auction-card';
import CollapsibleSection from './collapsible-section';


export default class AuctionsIndex extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      timeRemaining: [],
      serverTime: moment().utc()
    };
  }

  componentDidMount() {
    this.timerID = setInterval(
      () => this.tick(),
      500
    );
  }

  componentWillUnmount() {
    clearInterval(this.timerID);
  }


  tick() {
    let time = moment(ServerDate.now()).utc();
    this.setState({
      timeRemaining: _.reduce(this.props.auctionPayloads, (acc, auctionPayload) => {
        acc[_.get(auctionPayload, 'auction.id', 'temp')] = timeRemainingCountdown(auctionPayload, time);
          return acc
        }, {}),
      serverTime: time
    });
  }

  render() {
    const cardDateFormat = function(time){return moment(time).format("DD MMM YYYY, k:mm")};
    const currentUserIsBuyer = (auction) => { return(parseInt(this.props.currentUserCompanyId) === auction.buyer.id); };

    const filteredAuctionPayloads = (status) => {
      return _.filter(this.props.auctionPayloads, (auctionPayload) => {
          return(auctionPayload.state.status === status)
        });
    }

    const filteredAuctionsDisplay = (status) => {
      const filteredPayloads = filteredAuctionPayloads(status);
      if(_.isEmpty(filteredPayloads)) {
        return(
          <div className="empty-list">
            <em>{`You have no ${status} auctions`}</em>
          </div>);
      } else {
        return(
          <div className="columns is-multiline">
            { _.map(filteredPayloads, (auctionPayload) => {
              if (currentUserIsBuyer(auctionPayload.auction)) {
                return <BuyerAuctionCard
                  key={auctionPayload.auction.id}
                  auctionPayload={auctionPayload}
                  timeRemaining={this.state.timeRemaining[auctionPayload.auction.id]}
                />;
              } else {
                return <SupplierAuctionCard
                  key={auctionPayload.auction.id}
                  auctionPayload={auctionPayload}
                  timeRemaining={this.state.timeRemaining[auctionPayload.auction.id]}
                />;
              }
            }) }
          </div>);
      }
    };
    const filteredAuctionsCount = (status) => {
      return filteredAuctionPayloads(status).length;
    }

    return (
      <div className="has-margin-top-xl has-padding-top-lg">
        <div className="container is-fullhd">
          <div className="content has-margin-top-lg is-clearfix">
            <h1 className="title is-3 is-pulled-left has-text-weight-bold">Auction Listing</h1>
            <a href="/auctions/new" className="button is-link is-pulled-right">
              New Auction
            </a>
            <div className="auction-list__time-box">
              <div className="auction-list__timer">
                <i className="far fa-clock has-margin-right-xs"></i>
                <span className="auction-list__timer__clock" id="gmt-time" >
                  {this.state.serverTime.format("DD MMM YYYY, k:mm:ss")}
                </span>&nbsp;GMT
              </div>
              <i>Server Time</i>
            </div>

          </div>
        </div>
        <CollapsibleSection
          trigger="Active Auctions"
          classParentString="auction-list qa-open-auctions-list"
          contentChildCount={filteredAuctionsCount("open")}
          open={filteredAuctionsCount("open") > 0}
          >
          { filteredAuctionsDisplay("open") }
        </CollapsibleSection>
        <CollapsibleSection
          trigger="Auctions In Decision"
          classParentString="auction-list qa-open-auctions-list"
          contentChildCount={filteredAuctionsCount("decision")}
          open={filteredAuctionsCount("decision") > 0}
          >
          { filteredAuctionsDisplay("decision") }
        </CollapsibleSection>
        <CollapsibleSection
          trigger="Upcoming Auctions"
          classParentString="auction-list qa-open-auctions-list"
          contentChildCount={filteredAuctionsCount("pending")}
          open={filteredAuctionsCount("pending") > 0}
          >
          { filteredAuctionsDisplay("pending") }
        </CollapsibleSection>
        <CollapsibleSection
          trigger="Closed Auctions"
          classParentString="auction-list qa-open-auctions-list"
          contentChildCount={filteredAuctionsCount("closed")}
          open={filteredAuctionsCount("closed") > 0}
          >
          { filteredAuctionsDisplay("closed") }
        </CollapsibleSection>
        <CollapsibleSection
          trigger="Expired Auctions"
          classParentString="auction-list qa-open-auctions-list"
          contentChildCount={filteredAuctionsCount("expired")}
          open={filteredAuctionsCount("expired") > 0}
          >
          { filteredAuctionsDisplay("expired") }
        </CollapsibleSection>
      </div>
    );
  }
}
