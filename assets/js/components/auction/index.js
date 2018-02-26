import _ from 'lodash';
import React from 'react';
import { Link } from 'react-router';
import moment from 'moment';
import { formatTimeRemaining, timeRemainingCountdown, formatTimeRemainingColor} from '../../utilities';
import  ServerDate from '../../serverdate';


export default class AuctionsIndex extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      timeRemaining: []
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
      timeRemaining: _.reduce(this.props.auctions, (acc, auction) => {
        acc[_.get(auction, 'id', 'temp')] = timeRemainingCountdown(auction, time);
          return acc
        }, {})
    });
  }

  render() {
    const currentGMTTime = moment().utc().format("DD MMM YYYY, k:mm:ss");
    const gmtTimeElement = document.querySelector("#gmt-time")
    window.setInterval(
      function(){
        if (gmtTimeElement) {gmtTimeElement.innerHTML =  moment().utc().format("DD MMM YYYY, k:mm:ss");}
    }, 1000);
    const cardDateFormat = function(time){return moment(time).format("DD MMM YYYY, k:mm")};

    function AuctionTimeRemaining(auction, timeRemaining) {
      const auctionStatus = auction.state.status;
      const auctionTimer = timeRemaining[auction.id];
      if (auctionStatus == "open" || auctionStatus == "decision") {
        return (
          <span className={`auction-card__time-remaining auction-card__time-remaining--${formatTimeRemainingColor(auction, auctionTimer)}`}>
            <span className="icon has-margin-right-xs"><i className="far fa-clock"></i></span>
            <span
              className="qa-auction-time_remaining"
              id="time-remaining"
            >
              {formatTimeRemaining(auction, auctionTimer, "index")}
            </span>
          </span>
        );
      }
      else {
        return (
          <span className={`auction-card__time-remaining auction-card__time-remaining--${formatTimeRemainingColor(auction, auctionTimer)}`}>
            <span className="icon has-margin-right-xs"><i className="far fa-clock"></i></span>
            {cardDateFormat(auction.auction_start)}
          </span>
        );
      }
    };

    const AuctionCard = (auction) => (
      <div className="column is-one-third" key={auction.id}>
        <div className={`card qa-auction-${auction.id}`}>
          <div className="card-content">
            <div className="is-clearfix">
              {/* Start Status/Time Bubble */}
              <div className={`auction-card__status auction-card__status--${auction.state.status}`}>
                <span className="qa-auction-status">{auction.state.status}</span>
                {AuctionTimeRemaining(auction, this.state.timeRemaining)}
              </div>
              {/* End Status/Time Bubble */}
              {/* Start Link to Auction */}
                <a href={`/auctions/${auction.id}`} className="auction-card__link-to-auction"><span className="icon is-medium has-text-right"><i className="fas fa-2x fa-angle-right"></i></span></a>
              {/* End Link to Auction */}
              {/* Start Link to Auction Edit */}
                <a href={`/auctions/${auction.id}/edit`} className="auction-card__link-to-auction-edit"><span className="icon is-medium has-text-right"><i className="fas fa-lg fa-edit"></i></span></a>
              {/* End Link to Auction Edit */}
            </div>
          </div>
          <div className="card-title">
            <h3 className="title is-size-4 has-text-weight-bold is-marginless">{auction.vessel.name}</h3>
            <p className="has-family-header has-margin-bottom-xs">{auction.buyer.name}</p>
            <p className="has-family-header"><span className="has-text-weight-bold">{auction.port.name}</span> (<strong>ETA</strong> {cardDateFormat(auction.eta)} &ndash; <strong>ETD</strong> {cardDateFormat(auction.etd)})</p>
          </div>
          <div className="card-content__products">
            {auction.fuel.name} ({auction.fuel_quantity}&nbsp;MT)
          </div>
          <div className="card-content__products">
            <a href={`/auctions/start/${auction.id}`} className="card__start-auction button is-link is-small qa-auction-start"><span className="icon"><i className="fas fa-play"></i></span> Start Auction</a>
          </div>
  {/* BUYER ONLY */}
          <div className="card-content__auction-status has-margin-top-md">
              <div>Suppliers Participating</div>
              <div className="card-content__rsvp">
                <span className="icon has-text-success has-margin-right-xs"><i className="fas fa-check-circle"></i></span>0&nbsp;
                <span className="icon has-text-warning has-margin-right-xs"><i className="fas fa-adjust"></i></span>0&nbsp;
                <span className="icon has-text-danger has-margin-right-xs"><i className="fas fa-times-circle"></i></span>0&nbsp;
                <span className="icon has-text-dark has-margin-right-xs"><i className="fas fa-question-circle"></i></span>0&nbsp;
              </div>
          </div>
          <div className="card-content__bid-status">
            <div className="card-content__best-bidder">Lowest Bidder [Supplier(s)]</div>
            <div className="card-content__best-price"><strong>Their Offer: </strong>PRICE</div>
          </div>
          {/* <div className="card-content__auction-status">
              <div>Are you ready to post your auction?</div>
              <button className="button is-primary">Schedule Auction</button>
          </div> */}
  {/* / BUYER ONLY */}
  {/* SUPPLIER ONLY */}
          {/* <div className="card-content__auction-status">
            <div>Respond to Invitation</div>
            <div className="field has-addons">
              <p className="control">
                <a className="button is-success">
                  <span>Accept</span>
                </a>
              </p>
              <p className="control">
                <a className="button is-danger">
                  <span>Decline</span>
                </a>
              </p>
              <p className="control">
                <a className="button is-gray-3">
                  <span>Maybe</span>
                </a>
              </p>
            </div>
          </div>
          <div className="card-content__bid-status">
            <div className="card-content__best-bidder">Lowest Bidder [Supplier(s)]</div>
            <div className="card-content__best-price"><strong>Their Offer: </strong>PRICE</div>
          </div>
          <div className="card-content__bid">
            <div className="card-content__bid__title has-padding-right-xs">
              <div>Place Bid</div>
              <span className="icon is-inline-block has-text-dark has-margin-left-md"><i className="fas fa-plus"></i></span>
            </div>
          </div> */}
  {/* / SUPPLIER ONLY */}
  {/* ADMIN ONLY */}
          {/* <div className="card-content__bid-status">
            <div className="card-content__best-bidder">Lowest Bidder [Supplier(s)]</div>
            <div className="card-content__best-price"><strong>Their Offer: </strong>PRICE</div>
          </div>
          <div className="card-content__bid">
            <div className="card-content__bid__title has-padding-right-xs">
              <div>Place Bid</div>
              <span className="icon is-inline-block has-text-dark has-margin-left-md"><i className="fas fa-plus"></i></span>
            </div>
          </div>
          <div className="card-content__bid">
            <div className="card-content__bid__title">
              <div>Change RSVP</div>
              <div className="card-content__change-rsvp">
                <div className="card-content__rsvp">
                  <span className="icon has-text-success has-margin-right-xs"><i className="fas fa-check-circle"></i></span>0&nbsp;
                  <span className="icon has-text-warning has-margin-right-xs"><i className="fas fa-adjust"></i></span>0&nbsp;
                  <span className="icon has-text-danger has-margin-right-xs"><i className="fas fa-times-circle"></i></span>0&nbsp;
                  <span className="icon has-text-dark has-margin-right-xs"><i className="fas fa-question-circle"></i></span>0&nbsp;
                </div>
                <span className="icon is-inline-block has-text-dark has-margin-left-md"><i className="fas fa-plus"></i></span>
              </div>
            </div>
          </div> */}
  {/* / ADMIN ONLY */}
        </div>
      </div>
    );
    const filteredAuctionsDisplay = (status) => {
      const filteredAuctions = _.filter(this.props.auctions, (auction) => { return(auction.state.status === status)});
      if(_.isEmpty(filteredAuctions)) {
        return(
          <div className="empty-list">
            <em>{`You have no ${status} auctions`}</em>
          </div>);
      } else {
        return(
          <div className="columns is-multiline">
            { _.map(filteredAuctions, (auction) =>  {  return(AuctionCard(auction)); }) }
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
            <div class="auction-list__time-box">
              <div className="auction-list__timer">
                <i className="far fa-clock has-margin-right-xs"></i>
                <span className="auction-list__timer__clock" id="gmt-time" >{currentGMTTime}</span>&nbsp;GMT
              </div>
              <i>Clock Set to Server Time</i>
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
