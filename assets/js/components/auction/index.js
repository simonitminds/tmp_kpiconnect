import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { timeRemainingCountdown } from '../../utilities';
import ServerDate from '../../serverdate';
import AuctionCard from './auction-card';


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


    const filteredAuctionsDisplay = (status) => {
      const filteredAuctionPayloads = _.filter(this.props.auctionPayloads, (auctionPayload) =>
        { return(auctionPayload.state.status === status) }
      );
      if(_.isEmpty(filteredAuctionPayloads)) {
        return(
          <div className="empty-list">
            <em>{`You have no ${status} auctions`}</em>
          </div>);
      } else {
        return(
          <div className="columns is-multiline">
            { _.map(filteredAuctionPayloads, (auctionPayload) => {
              return <AuctionCard
                key={auctionPayload.auction.id}
                auctionPayload={auctionPayload} timeRemaining={this.state.timeRemaining}
                currentUserIsBuyer={currentUserIsBuyer(auctionPayload.auction)}
              />;
            }) }
          </div>);
      }
    };

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

        <section className="auction-list qa-open-auctions-list">
          <div className="container is-fullhd">
            <div className="content has-gray-lighter">
              <h2>Active Auctions</h2>
              { filteredAuctionsDisplay("open") }
            </div>
          </div>
        </section>

        <section className="auction-list qa-completed-auctions-list">
          <div className="container is-fullhd">
            <div className="content">
              <h2>Auctions In Decision</h2>
              { filteredAuctionsDisplay("decision") }
            </div>
          </div>
        </section>

        <section className="auction-list qa-pending-auctions-list">
          <div className="container is-fullhd">
            <div className="content">
              <h2>Upcoming Auctions</h2>
              { filteredAuctionsDisplay("pending") }
            </div>
          </div>
        </section>

        <section className="auction-list qa-completed-auctions-list">
          <div className="container is-fullhd">
            <div className="content">
              <h2>Closed Auctions</h2>
              { filteredAuctionsDisplay("closed") }
            </div>
          </div>
        </section>
      </div>
    );
  }
}
