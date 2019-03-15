import _ from 'lodash';
import React from 'react';
import { formatPrice } from '../../../../utilities';

const FuelPriceDisplay = ({products, auctionType}) => {
  const normalizeValue = (value) => {
    if (value < 0) {
      const newValue = value * -1;
      return newValue;
    } else {
      return value;
    }
  }

  const isFormulaRelated = auctionType == 'formula_related';

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
                    ? `${bid.amount > 0 && isFormulaRelated ? "+" : "-"}$${formatPrice(normalizeValue(bid.amount))}`
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
