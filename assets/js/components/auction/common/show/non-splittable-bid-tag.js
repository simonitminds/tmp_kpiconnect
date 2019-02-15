import React from 'react';
import _ from 'lodash';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

const NonSplittableBidTag = () => {
  return (
    <span className="auction__nonsplittable-bid-tag">
      <span action-label="Can't Be Split" className="auction__nonsplittable-bid-marker">
        <FontAwesomeIcon icon="ban" />
      </span>
      <span className="has-padding-left-sm">Unsplittable</span>
    </span>
  );
}

export default NonSplittableBidTag;
