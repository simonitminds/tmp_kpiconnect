import _ from 'lodash';
import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

const AuctionTitle = ({auction, detailed}) => {
  console.log(auction)
  const auctionType = _.get(auction, 'type');
  const showDetail = detailed === undefined ? true : detailed;
  const is_traded_bid_allowed = _.get(auction, 'is_traded_bid_allowed')

  switch (auctionType) {
    case ('spot'):
      const vessels = _.get(auction, 'vessels');
      return(
        <div>
          <span className="auction-header__auction-id">{auction.id}</span>
          { _.map(vessels, (vessel) => {
              return (
                <span key={vessel.name} className={`auction-header-item qa-auction-vessel-${vessel.id}`}>
                  <span className="auction-header__vessel-name has-margin-right-xs">{vessel.name}</span>
                  { showDetail &&
                    <span className="auction-header__vessel-imo has-text-gray-3 has-margin-right-xs">({vessel.imo})</span>
                  }
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
        <div>
          <span className="auction-header__auction-id">{auction.id}</span>
          <span className="auction-header__port-name qa-auction-port">{portName}</span>
          { showDetail &&
            <span className="auction-header__vessel-imo has-text-gray-3 has-margin-left-xs qa-auction-term">(Term)</span>
          }
          { is_traded_bid_allowed &&
            <span action-label="Traded Bids Accepted" className="auction__traded-bid-accepted-marker has-margin-left-sm"> <FontAwesomeIcon icon="exchange-alt" className="has-text-gray-3" />
            </span>
          }
        </div>
      );
  }
}

export default AuctionTitle;
