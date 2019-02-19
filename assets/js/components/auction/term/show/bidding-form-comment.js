import _ from 'lodash';
import React from 'react';

const BiddingFormComment = ({fuel, auctionPayload, supplierId}) => {
  const {id: fuelId} = fuel;
  const auction = _.get(auctionPayload, 'auction');
  const auctionStatus = _.get(auctionPayload, 'status');

  return (
    <div className="auction-bidding__product-group has-margin-bottom-md">
      <h3 className="auction-condition__title title is-size-6 is-uppercase has-margin-top-sm">Conditions</h3>
      <div className="auction-condition__form-body">
        <textarea
          type="text"
          id="bid"
          name="comment"
          data-fuel-input
          data-fuel={fuelId}
          className="textarea qa-auction-bid-condition">
        </textarea>
      </div>
    </div>
  );
};

export default BiddingFormComment;
