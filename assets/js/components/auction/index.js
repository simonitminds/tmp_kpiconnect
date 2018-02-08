import _ from 'lodash';
import React from 'react';
import { Link } from 'react-router';
import moment from 'moment';


const AuctionsIndex = (props)=> {

  const currentGMTTime = moment().utc().format("DD MMM YYYY, k:mm:ss");
  const gmtTimeElement = document.querySelector("#gmt-time")
  window.setInterval(
    function(){
      if (gmtTimeElement) {gmtTimeElement.innerHTML =  moment().utc().format("DD MMM YYYY, k:mm:ss");}
  }, 1000);
  const cardDateFormat = function(time){return moment(time).format("DD MMM YYYY, k:mm")};

  function AuctionTimeRemaining() {
    const auctionStatus = auction.state.status;

    if (auctionStatus == "open") {
      return <span className="auction-card__time-remaining auction-card__time-remaining--open">
              <span className="icon has-margin-right-xs"><i className="far fa-clock"></i></span>
                5:00 remaining
              </span>;
    }
    else {
      return <span className="auction-card__time-remaining auction-card__time-remaining--open">
              <span className="icon has-margin-right-xs"><i className="far fa-clock"></i></span>
                {cardDateFormat(auction.auction_start)}
              </span>;
    }
  };

  const AuctionCard = (auction) => (
    <div className="column is-one-third" key={auction.id}>
      <div className={`card qa-auction-${auction.id}`}>
        <div className="card-content has-padding-bottom-md">
          <div className="is-clearfix">
            {/* Start Status/Time Bubble */}
            <div className={`auction-card__status auction-card__status--${auction.state.status}`}>
              <span className="qa-auction-status">{auction.state.status}</span>
              <span className={`auction-card__time-remaining auction-card__time-remaining--${auction.state.status}`}>
                <span className="icon has-margin-right-xs"><i className="far fa-clock"></i></span>
                {auction.state.status === "open" ? "5:00 remaining" : `${cardDateFormat(auction.auction_start)}&nbsp;GMT`}
              </span>
            </div>
            {/* End Status/Time Bubble */}
            {/* Start Link to Auction */}
              <a href={`/auctions/${auction.id}`} className="auction-card__link-to-auction"><span className="icon is-medium has-text-right"><i className="fas fa-2x fa-angle-right"></i></span></a>
            {/* End Link to Auction */}
            {/* Start Link to Auction Edit */}
              <a href={`/auctions/${auction.id}/edit`} className="auction-card__link-to-auction-edit"><span className="icon is-medium has-text-right"><i className="fas fa-lg fa-edit"></i></span></a>
            {/* End Link to Auction Edit */}

          </div>
          <div className="card-title">
            <h3 className="title is-size-4 has-text-weight-bold is-marginless">{auction.vessel.name}</h3>
            <p className="has-family-header">{auction.buyer.company.name}</p>
            <p className="has-family-header has-margin-top-xs"><span className="has-text-weight-bold">{auction.port.name}</span> (<strong>ETA</strong> {cardDateFormat(auction.eta)} &ndash; <strong>ETD</strong> {cardDateFormat(auction.etd)})</p>
          </div>
          <div className="has-text-weight-bold has-margin-top-md">
            {auction.fuel.name} ({auction.fuel_quantity}&nbsp;MT)
          </div>
          <div className="card-content__best-price">
            <strong>Best Offer: </strong> PRICE
          </div>
        </div>
        <footer className="card-footer">
          <a href={`/auctions/start/${auction.id}`} className="card-footer-item qa-auction-start">Start</a>
        </footer>
      </div>
   </div>
  );

  const filteredAuctionsDisplay = (status) => {
    const filteredAuctions = _.filter(props.auctions, (auction) => { return(auction.state.status === status)});
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
          <div className="auction-list__timer">
            <i className="far fa-clock has-margin-right-xs"></i>
            <span className="auction-list__timer__time" id="gmt-time" >{currentGMTTime}</span>GMT
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
  )
}

export default AuctionsIndex;
