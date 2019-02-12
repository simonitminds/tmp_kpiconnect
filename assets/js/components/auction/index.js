import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { cardDateFormat, timeRemainingCountdown } from '../../utilities';
import ServerDate from '../../serverdate';
import BuyerAuctionCard from './buyer-auction-card';
import SupplierAuctionCard from './supplier-auction-card';
import CollapsibleSection from './common/collapsible-section';
import ChannelConnectionStatus from './channel-connection-status';
import MediaQuery from 'react-responsive';


export default class AuctionsIndex extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      timeRemaining: {},
      serverTime: moment().utc()
    };
  }

  // componentDidMount() {
  //   this.timerID = setInterval(
  //     () => this.tick(),
  //     500
  //   );
  // }

  componentWillUnmount() {
    clearInterval(this.timerID);
  }


  tick() {
    let time = moment(ServerDate.now()).utc();
    this.setState({
      timeRemaining: _.reduce(this.props.auctionPayloads, (acc, auctionPayload) => {
        acc[_.get(auctionPayload, 'auction.id', 'temp')] = timeRemainingCountdown(auctionPayload, time);
          return acc;
        }, {}),
      serverTime: time
    });
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
        case 'closed':
        case 'cancelled':
        case 'expired':
          sortField = 'auction_closed_time';
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
                <a href="/auctions/new" className="auction-list__new-auction button is-link is-pulled-right is-small">
                  New Auction
                </a>
              </div>
            </MediaQuery>
            <h1 className="auction-list__title title is-3">Auction Listing</h1>
            <MediaQuery query="(min-width: 600px)">
              <div>
                <a href="/auctions/new" className="button is-link is-pulled-right">
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
          <CollapsibleSection
            trigger="Closed Auctions"
            classParentString="qa-closed-auctions-list auction-list"
            contentChildCount={filteredAuctionsCount("closed")}
            open={filteredAuctionsCount("closed") > 0}
            >
            { filteredAuctionsDisplay("closed") }
          </CollapsibleSection>
          <CollapsibleSection
            trigger="Expired Auctions"
            classParentString="qa-expired-auctions-list auction-list"
            contentChildCount={filteredAuctionsCount("expired")}
            open={filteredAuctionsCount("expired") > 0}
            >
            { filteredAuctionsDisplay("expired") }
          </CollapsibleSection>
          <CollapsibleSection
            trigger="Canceled Auctions"
            classParentString="qa-canceled-auctions-list auction-list"
            contentChildCount={filteredAuctionsCount("canceled")}
            open={filteredAuctionsCount("canceled") > 0}
            >
            { filteredAuctionsDisplay("canceled") }
          </CollapsibleSection>

        </div>
      </div>
    );
  }
}
