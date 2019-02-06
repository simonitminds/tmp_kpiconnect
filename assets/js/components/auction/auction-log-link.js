import React from 'react';

const AuctionLogLink = ({auction}) => {
  return(
      <a
        className="button is-info has-family-copy"
        href={`/auctions/${auction.id}/log`}
      >
        Auction Log
      </a>
  );
};

export default AuctionLogLink;
