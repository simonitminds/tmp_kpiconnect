import React from 'react';
import _ from 'lodash';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import Downshift from 'downshift';
import { formatPrice } from '../../utilities';

const CustomSolutionBidSelector = (props) => {
  const {
    bids,
    onChange
  } = props;

  // <div className="select">
  //   <select defaultValue="" onChange={}>
  //     <option value="">No bid selected</option>
  //     { _.map(bids, (bid) => {
  //         return (
  //           <option value={bid.id} key={bid.id}>
  //             ${formatPrice(bid.amount)} - {bid.supplier}
  //           </option>
  //         );
  //       })
  //     }
  //   </select>
  // </div>

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
      return (
        <div {...getItemProps({ item: bid, key: bid.id })}>
          <strong>${formatPrice(bid.amount)}</strong> - {bid.supplier}
          { isTradedBid(bid) }
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
        <div style={{position: "relative", zIndex: 10}}>
          <div className="select" {...getToggleButtonProps()}>
            { renderBid({bid: selectedItem, getItemProps}) }
          </div>
          { selectedItem &&
            <button onClick={clearSelection}><FontAwesomeIcon icon="times" /></button>
          }
          { isOpen &&
            <div style={{position: "absolute", top: "100%", backgroundColor: "white"}}>
              { _.map(bids, (bid) => renderBid({bid, getItemProps})) }
            </div>
          }
        </div>
      )}
    </Downshift>
  );
};

export default CustomSolutionBidSelector;
