import React from 'react';

const AuctionLogLink = ({auction}) => {
  return(
    <div>
      <a
        className="button is-primary is-small has-family-copy is-capitalized"
        href={`/auctions/${auction.id}/log`}
      >
        Auction Log
      </a>
    </div>
  );
};

export default AuctionLogLink;
