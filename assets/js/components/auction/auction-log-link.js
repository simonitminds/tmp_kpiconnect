import React from 'react';

const AuctionLogLink = ({auction}) => {
  return(
    <div className="box">
        <h3 className="box__header box__header--bordered has-margin-bottom-md">Auction Reports</h3>
      <a
        className="button is-info has-family-copy is-capitalized"
        href={`/auctions/${auction.id}/log`}
      >
        Auction Log
      </a>
    </div>
  );
};

export default AuctionLogLink;
