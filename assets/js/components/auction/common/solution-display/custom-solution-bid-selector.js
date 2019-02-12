import React from 'react';
import _ from 'lodash';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import Downshift from 'downshift';
import { formatPrice } from '../../../../utilities';

// The `bids` object passed to this component can supply additional information
// on each bid indicating if it should be disabled, and if so, a message of why
// the bid has been disabled (e.g., an unsplittable bid for another product was
// selected). The props are `disabled` and `disabledReason` respectively.
const CustomSolutionBidSelector = (props) => {
  const {
    bids,
    className,
    onChange
  } = props;

  const isTradedBid = (bid) => {
    if(bid.is_traded_bid) {
      return(
        <span className="auction__traded-bid-tag">
          <span action-label="Traded Bid" className="auction__traded-bid-marker">
            <FontAwesomeIcon icon="exchange-alt" />
          </span>
          <span className="has-padding-left-sm">Traded Bid</span>
        </span>
      );
    };
    return;
  }

  const isNonsplittableBid = (bid) => {
    if(bid.allow_split == false) {
      return(
        <span className="auction__nonsplittable-bid-tag">
          <span action-label="Can't Be Split" className="auction__nonsplittable-bid-marker">
            <FontAwesomeIcon icon="ban" />
          </span>
          <span className="has-padding-left-sm">Unsplittable</span>
        </span>
      );
    };
    return;
  }

  const renderBid = ({bid, getItemProps}) => {
    if(bid) {
      const { id, amount, supplier, disabled, disabledReason} = bid;

      return (
        <div className={`custom-bid__dropdown__list qa-bid-${bid.id}`} {...getItemProps({ item: bid, key: id })}>
          <span className="custom-bid__supplier"><strong className="has-margin-right-xs">${formatPrice(amount)}</strong> - {supplier}</span>
          { isTradedBid(bid) }
          { isNonsplittableBid(bid) }
        </div>
      );
    } else {
      return (
        <div {...getItemProps({item: bid, key: ""})} style={{padding: "6px 10px"}}>
          <span className="is-italic">No bid selected</span>
        </div>
      );
    }
  }

  return (
    <Downshift onChange={onChange} itemToString={bid => bid ? bid.id : ""}>
      {({
        getItemProps,
        getToggleButtonProps,
        isOpen,
        highlightedIndex,
        selectedItem,
        clearSelection
      }) => (
        <div className={`${className} custom-bid__dropdown__head`}>
          <div className="select select--custom-bid" {...getToggleButtonProps()}>
            { renderBid({bid: selectedItem, getItemProps}) }
          </div>
          { selectedItem &&
            <button className="button button--icon" onClick={clearSelection}><FontAwesomeIcon icon="times" /></button>
          }
          { isOpen &&
            <div className="select__custom-dropdown">
              { _.map(bids, (bid) => renderBid({bid, getItemProps})) }
            </div>
          }
        </div>
      )}
    </Downshift>
  );
};

export default CustomSolutionBidSelector;
