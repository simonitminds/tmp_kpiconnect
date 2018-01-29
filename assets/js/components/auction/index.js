import _ from 'lodash';
import React from 'react';
import { Link } from 'react-router';

const AuctionsIndex = (props)=> {
  return (
    <div>
      <div className="container is-fullhd">
        <div className="content has-margin-top-lg is-clearfix">
          <h1 className="title is-3 is-pulled-left has-text-weight-bold">Auction Listing</h1>
          <a href="/auctions/new" className="button is-link is-pulled-right">
            New Auction
          </a>
        </div>
      </div>

      <section className="auction-list">
        <div className="container is-fullhd">
          <div className="content has-gray-lighter">
            <h2>Active Auctions</h2>
            <div className="columns is-multiline">

              {_.map(props.auctions, (auction)=> (
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
                  </div>))}
            </div>
          </div>
        </div>
      </section>

      <section className="auction-list">
        <div className="container is-fullhd">
          <div className="content">
            <h2>Upcoming Auctions</h2>
            <div className="empty-list">
              <em>You have no upcoming auctions</em>
            </div>
          </div>
        </div>
      </section>
      <section className="auction-list">
        <div className="container is-fullhd">
          <div className="content">
            <h2>Completed Auctions</h2>
            <div className="empty-list">
              <em>You have no completed auctions</em>
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}

export default AuctionsIndex;
