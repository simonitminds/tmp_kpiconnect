import _ from 'lodash';
import React from 'react';
import CollapsibleSection from './collapsible-section';

export default class Message extends React.Component {
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
    const messagePayloads = this.props.messagePayloads;
    const isExpanded = this.state.expanded;
    const renderMessagesInterface = (messagePayloads) => {
      return (
        <ul className="message__context-list">
          { _.map(messagePayloads, (messagePayload) => {
            return(
                <li key={messagePayload.auction_id} className={`qa-auction-${messagePayload.auction_id}-message-payloads`}>
                <h2>
                  <div className={`auction-header__status auction-header__status-${messagePayload.status} tag is-rounded has-margin-bottom-non has-margin-right-xs is-capitalized`}>
                    {messagePayload.status}
                  </div>
                  { _.map(messagePayload.vessels, (vessel) => {
                    return(
                      <span key={vessel.id}>{vessel.name} <span className="has-text-gray-3">({vessel.imo})</span></span>
                    );
                  }) }
                  <ul className="qa-conversations">
                    { _.map(messagePayload.conversations, (conversation) => {
                      return(
                        <li key={conversation.company_name}>{conversation.company_name}</li>
                      );
                    }) }
                  </ul>
                </h2>
              </li>
            );
          })}
        </ul>
      );
    }

    return(
      <div className={`qa-auction-messages ${isExpanded ? "open" : "closed"}`} onClick={this.toggleExpanded.bind(this)}>
        <div className="message__notification-context">
          <div className="message__menu-bar">
            <h1 className="message__menu-bar__title">Messages</h1>
            <div className="message__notifications message__notifications--has-unread">
              <i className="fas fa-envelope has-margin-right-sm"></i>
            </div>
          </div>
        </div>
        <div className="message__conversation-list qa-auction-messages-auctions">
          {isExpanded && renderMessagesInterface(messagePayloads)}
        </div>
      </div>
    );
  }
}
