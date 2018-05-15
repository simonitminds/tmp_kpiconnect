import React from 'react';
import _ from 'lodash';

const AuctionBreadCrumbs = ({auction}) => {
  const auction_id = _.get(auction, 'id');
  return(
    <section className="auction-page"> {/* Breadcrumb information */}
      <div className="container has-margin-top-lg">
        <nav className="breadcrumb has-succeeds-separator has-family-header has-text-weight-bold has-padding-top-md" aria-label="breadcrumbs">
          <ul>
            <li><a href="/auctions">Auctions</a></li>
            <li className="is-active"><a href="#" aria-current="page">Auction ({auction.id})</a></li>
          </ul>
        </nav>
      </div>
    </section>
  );
};
export default AuctionBreadCrumbs;
