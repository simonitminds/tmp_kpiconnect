import React from 'react';
import _ from 'lodash';
import { formatPrice } from '../../utilities';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

const BidTag = ({bid, title, highlightOwn}) => {
  return (
    <div className="tags auction-bidding__best-price has-addons">
      <span className="tag is-gray-3 has-family-copy has-text-weight-bold is-capitalized has-margin-bottom-none">
        {highlightOwn && <span className="has-text-gold has-margin-right-sm"><FontAwesomeIcon icon="crown" /></span>}
        <span className="truncate">{title}</span>
      </span>
      { bid
        ? <span className="tag is-yellow has-family-copy has-text-weight-bold is-capitalized has-margin-bottom-none">${formatPrice(bid.amount)}</span>
        : <span className="tag is-gray-2 has-family-copy has-text-weight-bold is-capitalized has-margin-bottom-none"><i>None</i></span>
      }
    </div>
  );
}

export default BidTag;
