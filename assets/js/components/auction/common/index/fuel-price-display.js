import _ from 'lodash';
import React from 'react';
import { formatPrice } from '../../../../utilities';

const FuelPriceDisplay = ({products, auctionType}) => {
  return (
    <React.Fragment>
      { _.map(products, ({fuel, quantity, bid}) => {
          return(
            <div className="card-content__product" key={fuel.id}>
              <span className="fuel-name">{fuel.name}</span>
              { auctionType == "spot" ?
                <span className="fuel-amount has-text-gray-3">({quantity}&nbsp;MT)</span>
                : <span className="fuel-amount has-text-gray-3">({quantity}&nbsp;MT/mo)</span>
              }
              <span className="card-content__best-price">
                { bid
                  ? `$${formatPrice(bid.amount)}`
                  : "No bid"
                }
              </span>
            </div>
          );
        })
      }
    </React.Fragment>
  );
};

export default FuelPriceDisplay;
