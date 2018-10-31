import _ from 'lodash';
import React from 'react';
import CollapsibleSection from './collapsible-section';

export default class AuctionMessage extends React.Component {
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
    const {messagePayloads, auctionPayloads} = this.props;
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
        <ul className="message__context-list">
          { _.map(filteredAuctionsPayloads(auctionPayloads), (auctionPayload) => {
            return(
                <li key={auctionPayload.auction.id} className={`qa-auction-message-auction-${auctionPayload.auction.id}`}>
                <h2>
                  <div className={`auction-header__status auction-header__status-${auctionPayload.status} tag is-rounded has-margin-bottom-non has-margin-right-xs is-capitalized`}>{auctionPayload.status}</div>
                  { _.map(auctionPayload.auction.vessels, (vessel) => {
                    return(
                        <span key={vessel.id}>{vessel.name} <span className="has-text-gray-3">({vessel.imo})</span></span>
                    );
                  }) }
                </h2>
              </li>
            );
          })}
        </ul>
      );
    }

    return(
      <div className={`qa-auction-message ${isExpanded ? "open" : "closed"}`} onClick={this.toggleExpanded.bind(this)}>
        <div className="message__notification-context">
          <div className="message__menu-bar">
            <h1 className="message__menu-bar__title">Messages</h1>
            <div className="message__notifications message__notifications--has-unread">
              <i className="fas fa-envelope has-margin-right-sm"></i>
            </div>
          </div>
        </div>
        <div className="message__conversation-list qa-auction-message-auctions">
          {isExpanded && renderSupplierContext(auctionPayloads)}
        </div>
      </div>
    );
  }
}
