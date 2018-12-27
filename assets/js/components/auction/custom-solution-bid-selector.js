import React from 'react';
import _ from 'lodash';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import Downshift from 'downshift';
import { formatPrice } from '../../utilities';

// The `bids` object passed to this component can supply additional information
// on each bid indicating if it should be disabled, and if so, a message of why
// the bid has been disabled (e.g., an unsplittable bid for another product was
// selected). The props are `disabled` and `disabledReason` respectively.
const CustomSolutionBidSelector = (props) => {
  const {
    bids,
    onChange
  } = props;

  const isTradedBid = (bid) => {
    return(
      <span>
        { bid.is_traded_bid
          ? <span className="auction__traded-bid-tag">
              <span action-label="Traded Bid" className="auction__traded-bid-marker">
                <FontAwesomeIcon icon="exchange-alt" />
              </span>
              <span className="has-padding-left-sm">Traded Bid</span>
            </span>
          : ""
        }
      </span>
    );
  }

  const isNonsplittableBid = (bid) => {
    return(
      <span>
        { bid.allow_split == false
          ? <span className="auction__nonsplittable-bid-tag">
              <span action-label="Can't Be Split" className="auction__nonsplittable-bid-marker">
                <FontAwesomeIcon icon="ban" />
              </span>
              <span className="has-padding-left-sm">Unsplittable</span>
            </span>
          : ""
        }
      </span>
    );
  }

  const renderBid = ({bid, getItemProps}) => {
    if(bid) {
      const { id, amount, supplier, disabled, disabledReason} = bid;

      return (
        <div {...getItemProps({ item: bid, key: id })} style={{padding: "6px 10px"}}>
          <strong>${formatPrice(amount)}</strong> - {supplier}
          { isTradedBid(bid) }
          { isNonsplittableBid(bid) }
        </div>
      );
    } else {
      return (
        <div {...getItemProps({item: bid, key: ""})}>
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
        <div style={{position: "relative", display: "flex"}}>
          <div className="select" {...getToggleButtonProps()}>
            { renderBid({bid: selectedItem, getItemProps}) }
          </div>
          { selectedItem &&
            <button onClick={clearSelection}><FontAwesomeIcon icon="times" /></button>
          }
          { isOpen &&
            <div style={{position: "absolute", top: "100%", zIndex: 10, backgroundColor: "white"}}>
              { _.map(bids, (bid) => renderBid({bid, getItemProps})) }
            </div>
          }
        </div>
      )}
    </Downshift>
  );
};

export default CustomSolutionBidSelector;
