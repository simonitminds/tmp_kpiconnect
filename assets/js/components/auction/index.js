import _ from 'lodash';
import React from 'react';
import { Link } from 'react-router';
import moment from 'moment';


const AuctionsIndex = (props)=> {

  // =============================================================== //
  //                          GMT TIME                               //
  // (Where Lauren tries to get the current time in GMT into the UI) //
  // =============================================================== //
  // =============================================================== //

  const gmtTimeElement = document.querySelector('#gmt-time');
    window.setInterval(function(){
      if (gmtTimeElement) {
        gmtTimeElement.innerHTML =  moment().utc().format("k:mm:ss");
      }
  }, 1000);

  const AuctionCard = (auction) => (
    <div className="column is-one-third" key={auction.id}>
      <div className={`card qa-auction-${auction.id}`}>
        <div className="card-content has-padding-bottom-md">
          <div className="is-clearfix">
            <p className="has-text-weight-bold is-pulled-left">{auction.po}</p>
            <div className="auction-header__status tag is-rounded is-pulled-right has-margin-left-md has-text-weight-bold qa-auction-status">
              {auction.state.status}
            </div>
            <p className="is-pulled-right">{auction.auction_start}</p>
          </div>
          <div className="card-title">
            <h3 className="title is-size-4 has-text-weight-bold is-marginless">{auction.vessel.name}</h3>
            <p className="has-family-header has-margin-top-xs"><span className="has-text-weight-bold">{auction.port.name}</span> (<strong>ETA</strong> {auction.eta} &ndash; <strong>ETD</strong> {auction.etd})</p>
          </div>
          <div className="has-text-weight-bold has-margin-top-md">
            {auction.fuel.name} ({auction.fuel_quantity}&nbsp;MT)
          </div>
          <div className="card-content__best-price">
            <strong>Best Offer: </strong> PRICE
          </div>
        </div>
        <footer className="card-footer">
          <a href={`/auctions/${auction.id}`} className="card-footer-item">Show</a>
          <a href={`/auctions/${auction.id}/edit`} className="card-footer-item">Edit</a>
          <a href={`/auctions/start/${auction.id}`} className="card-footer-item qa-auction-start">Start</a>
        </footer>
      </div>
   </div>
  );

  const filteredAuctionsDisplay = (status) => {
    const filteredAuctions = _.filter(props.auctions, (auction) => { return(auction.state.status === status)});
    if(filteredAuctions.length === 0) {
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
          <div className="tag is-rounded is-highlit is-pulled-right is-medium has-margin-right-md has-text-weight-bold"><i className="far fa-clock has-margin-right-xs"></i><span className="tag__timer" id="gmt-time" >12:00:00</span>GMT</div>
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
            <h2>Completed Auctions</h2>
            { filteredAuctionsDisplay("completed") }
          </div>
        </div>
      </section>
    </div>
  )
}

export default AuctionsIndex;
