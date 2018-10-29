import _ from 'lodash';
import React from 'react';
import CollapsibleSection from './collapsible-section';

export default class AuctionMessaging extends React.Component {
  constructor(props) {
    super(props);
    const isExpanded = this.props.isExpanded;
    this.state = {
      expanded: isExpanded
    }
  }

  toggleExpanded(e) {
    e.preventDefault();
    this.setState({expanded: !this.state.expanded});
  }

  render() {
    const {messagingPayloads, auctionPayloads} = this.props;
    const isExpanded = this.state.expanded;

    const filteredAuctionsPayloads = (auctionPayloads) => {
      return _.filter(auctionPayloads, (auctionPayload) => {
        return _.includes(["pending", "open", "decision", "closed", "expired"], auctionPayload.status);
      });
    }

    const filteredAuctionsCount = (auctionPayloads) => {
      return filteredAuctionsPayloads(auctionPayloads).length;
    }

    const auctionCount = filteredAuctionsCount(auctionPayloads);

    const renderSupplierContext = (auctionPayloads) => {
      return (
        <ul className="messaging__context-list">
          { _.map(filteredAuctionsPayloads(auctionPayloads), (auctionPayload) => {
            return(
                <li key={auctionPayload.auction.id} className={`qa-auction-messaging-auction-${auctionPayload.auction.id}`}>
                <h2>
                  <div className={`auction-header__status auction-header__status-${auctionPayload.status} tag is-rounded has-margin-bottom-non has-margin-right-xs is-capitalized`}>{auctionPayload.status}</div>
                  { _.map(auctionPayload.auction.vessels, (vessel) => {
                    return(
                        <span key={vessel.id}>{vessel.name} <span className="has-text-gray-3">{vessel.imo}</span></span>
                    );
                  }) }
                </h2>
                <span className="is-inline-block has-margin-left-xs has-margin-top-xs">{auctionPayload.auction.buyer.name}<span className="has-text-gray-3 has-margin-left-xs">(Buyer)</span></span>
              </li>
            );
          })}
        </ul>
      );
    }

    return(
      <div className={`messaging qa-auction-messaging ${isExpanded ? "open" : "closed"}`} onClick={this.toggleExpanded.bind(this)}>
        <div className="messaging__notification-context">
          <div className="messaging__menu-bar">
            <h1 className="messaging__menu-bar__title">Messages</h1>
            <div className="messaging__notifications messaging__notifications--has-unread">
              <i className="fas fa-envelope has-margin-right-sm"></i>
            </div>
          </div>
        </div>
        <div className="messaging__conversation-list qa-auction-messaging-auctions">
          {isExpanded && renderSupplierContext(auctionPayloads)}
        </div>
      </div>
    );
  }
}
