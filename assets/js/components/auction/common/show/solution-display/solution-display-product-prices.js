import React from 'react';
import _ from 'lodash';
import { formatTime, formatPrice } from '../../../../../utilities';
import BidTag from '../../bid-tag';

const SolutionDisplayProductPrices = (props) => {
  const {
    highlightOwn,
    lowestFuelBids,
    supplierId
  } = props;

  return (
    <div className="auction-solution__header__row auction-solution__header__row--preview">
      <h4 className="has-text-weight-bold">Product Prices</h4>
      { _.map(lowestFuelBids, (bid, fuel) => {
          const highlight = highlightOwn && supplierId && bid && (bid.supplier_id == supplierId);
          return(
            <div className="control has-margin-bottom-none" key={fuel}>
              <BidTag title={fuel} highlightOwn={highlight} bid={bid}/>
            </div>
          )
        })
      }
    </div>
  );
};

export default SolutionDisplayProductPrices;
