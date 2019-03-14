import React from 'react';
import _ from 'lodash';
import { formatPrice } from '../../../utilities';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

/* BidTag
 *
 * Renders a small tag with the title and the amount from the given `bid`. If
 * `highlightOwn` is truthy, a crown will appear next to the title.
 */
const BidTag = ({bid, title, highlightOwn, indexPrice, auctionType}) => {

  return (
    <div className="tags auction-bidding__best-price has-addons">
      <span className="tag is-gray-3 has-family-copy has-text-weight-bold is-capitalized has-margin-bottom-none">
        {highlightOwn && <span className="has-text-gold has-margin-right-sm"><FontAwesomeIcon icon="crown" /></span>}
        <span className="truncate">{title}</span>
      </span>
        { bid
          ? <span className={`tag ${indexPrice ? 'is-teal has-text-white' : 'is-yellow'} has-family-copy has-text-weight-bold is-capitalized has-margin-bottom-none`}> {auctionType == 'formula_related' ? "+" : ""}${ indexPrice ? formatPrice(bid) : formatPrice(bid.amount)}</span>
          : <span className="tag auction-bidding__best-price--price has-family-copy has-text-weight-bold is-capitalized has-margin-bottom-none"><i>None</i></span>
        }
    </div>
  );
}

export default BidTag;
