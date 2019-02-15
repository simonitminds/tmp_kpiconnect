import React from 'react';
import _ from 'lodash';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

const TradedBidTag = ({className}) => {
  return (
    <span className={`auction__traded-bid-tag ${className || ''}`}>
      <span action-label="Traded Bid" className="auction__traded-bid-marker">
        <FontAwesomeIcon icon="exchange-alt" />
      </span>
      <span className="has-padding-left-sm">Traded Bid</span>
    </span>
  );
}

export default TradedBidTag;
