import React from 'react';
import _ from 'lodash';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { formatTime, formatPrice } from '../../../../utilities';

/* BidTable
 *
 * A component for rendering bid lists in a consistent style. Allows
 * customization of which attributes of the bids are displayed.
 *
 * `bids` should be a single, flat list bids. To render multiple groups of
 * bids, render this component multiple times.
 *
 * `columns` is the list of columns to display for each bid. For example,
 * A buyer view might show `["supplier", "amount", "time_entered"]`, while
 * the supplier view might show `["product", "amount", "time_entered"]`.
 *
 * By default, the `amount` column will also include the `Traded Bid` and
 * `Unsplittable` tags if they apply. If `showMinAmounts` is true, any
 * `amount` display will also include the `min_amount` value if present.
 */
const BidTable = ({isFormulaRelated, bids, columns, headers, showMinAmounts=false, className}) => {
  // If `headers` is given, it will be used for the header row of the table.
  // Otherwise, the `columns` names will be used instead.
  const tableHeaders = headers || _.map(columns, (c) => _.startCase(_.toLower(c)));
  const columnContent = (bid, column) => {
    const value = bid[column];

    switch(column) {
      case 'amount':
        const minAmount = bid.min_amount;
        const isTradedBid = bid.is_traded_bid;
        return (
          <React.Fragment>
            <span className="auction__bid-amount">{isFormulaRelated ? "+" : ""}${formatPrice(value)}</span>
            { showMinAmounts && minAmount &&
              <i className="has-text-gray-4"> (Min: ${formatPrice(minAmount)})</i>
            }
            <span className="qa-auction-bid-is_traded_bid">
              { isTradedBid &&
                <span className="auction__traded-bid-tag">
                  <span action-label="Traded Bid" className="auction__traded-bid-marker">
                    <FontAwesomeIcon icon="exchange-alt" />
                  </span>
                  <span className="has-padding-left-sm">Traded Bid</span>
                </span>
              }
            </span>
          </React.Fragment>
        );

      case 'time_entered':
        return formatTime(value);

      default:
        return value;
    }
  }


  return (
    <table className={`table is-fullwidth is-striped is-marginless ${className}`}>
      <thead>
        <tr>
          { _.map(tableHeaders, (header) => <th key={header}>{ header }</th>) }
        </tr>
      </thead>

      <tbody>
        { bids.length > 0
          ? _.map(bids, (bid) => {
              return (
                <tr key={bid.id} className={`qa-auction-bid-${bid.id}`}>
                  { _.map(columns, (column) => {
                      return <td key={column} className={`qa-auction-bid-${column}`}>{columnContent(bid, column)}</td>
                    })
                  }
                </tr>
              );
            })
          : <tr>
              <td colSpan={columns.length}><i>No bids have been placed on this product</i></td>
            </tr>
        }
      </tbody>
    </table>
  );
}

export default BidTable;
