import _ from 'lodash';
import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

const AuctionTitle = ({auction}) => {
  const auctionType = _.get(auction, 'type');
  const is_traded_bid_allowed = _.get(auction, 'is_traded_bid_allowed')

  switch (auctionType) {
    case ('spot'):
      const vessels = _.get(auction, 'vessels');
      return(
        <div className="">
          <span className="has-text-gray-3 is-inline-block has-padding-right-sm auction-title__auction-id">{auction.id}</span>
          { _.map(vessels, (vessel) => {
              return (
                <span key={vessel.name} className={`auction-title-item qa-auction-vessel-${vessel.id}`}>
                  <span className="auction-title__vessel-name">{vessel.name}</span>
                </span>
              );
            })
          }
          { is_traded_bid_allowed &&
            <span action-label="Traded Bids Accepted" className="auction__traded-bid-accepted-marker"> <FontAwesomeIcon icon="exchange-alt" className="has-text-gray-3" />
            </span>
          }
        </div>
      );

    default:
      const portName = _.get(auction, 'port.name');
      return(
        <div className="">
          <span className="has-text-gray-3 is-inline-block has-padding-right-sm auction-title__auction-id">{auction.id}</span>
          <span className="auction-title__port-name qa-auction-port">{portName}</span> <span className="auction-title__vessel-imo has-text-gray-3 has-margin-left-xs">(Term)</span>
          { is_traded_bid_allowed &&
            <span action-label="Traded Bids Accepted" className="auction__traded-bid-accepted-marker has-margin-left-sm"> <FontAwesomeIcon icon="exchange-alt" className="has-text-gray-3" />
            </span>
          }
        </div>
      );
  }
}

export default AuctionTitle;
