import _ from 'lodash';
import React from 'react';
import CollapsibleSection from './auction/collapsible-section';
import MessagePanel from './message-panel';

class Messages extends React.Component {
  constructor(props) {
    super(props);
    this.state = {};
  }

  componentDidUpdate() {

  }

  render() {
    const {
      connection,
      expandedAuction,
      expandedConversation,
      messagePanelIsExpanded,
      messagePayloads,
      sendMessage,
      toggleExpanded
    } = this.props;

    const unseenMessageCount = (unseenMessageCount) => {
      if (unseenMessageCount > 0) {
        return <span className="messaging__notifications qa-messages-unseen-count">{unseenMessageCount}</span>
      }
    }

    const expansionToggle = (isExpanded) => {
      return (
        <span className="collapsible-section__toggle-icon">
          <i className={`fas ${isExpanded ? `fa-angle-down` : `fa-angle-up`}`}></i>
        </span>
      )
    }

    const messagePanel = (auctionId, conversation) => {
      return <MessagePanel
                auctionId={auctionId}
                connection={connection}
                messages={conversation.messages}
                recipientCompany={conversation.company_name}
                sendMessage={sendMessage}
              />
    }

    const renderExpandableConversation = (auctionId, conversation, isExpanded) => {
      const unseenCount = _.chain(conversation.messages)
        .filter(['has_been_seen', false])
        .filter(['author_is_me', false])
        .size()
        .value()
      return (
        <li
          key={conversation.company_name}
          className={`qa-conversation-company-${conversation.company_name} ${isExpanded ? "open" : "closed"} ${unseenCount > 0 ? "with-unseen" : ""}`}
          onClick={toggleExpanded.bind(this, 'expandedConversation', conversation.company_name)}
        >
          <div>
            { expansionToggle(isExpanded) }
            { conversation.company_name }
            { unseenMessageCount(unseenCount) }
          </div>
          { isExpanded && messagePanel(auctionId, conversation) }
        </li>
      )
    }

    const renderConversations = (messagePayload, isExpanded) => {
      if (isExpanded) {
        return (
          <ul className="messaging__context-list qa-conversations">
            <li className="messaging__context-list__selector">Select a Conversation</li>
            { _.map(messagePayload.conversations, (conversation) => {
               return renderExpandableConversation(messagePayload.auction_id, conversation, expandedConversation == conversation.company_name)
             })}
          </ul>
        )
      } else {
        return ""
      }
    }

    const renderExpandableAuctionMessagePayload = (messagePayload, isExpanded) => {
      return (
        <li
          key={messagePayload.auction_id}
          className={`qa-auction-${messagePayload.auction_id}-message-payloads ${isExpanded ? "open" : "closed"} ${messagePayload.unseen_messages && "with-unseen"}`}
          onClick={toggleExpanded.bind(this, 'expandedAuction', messagePayload.auction_id)}
        >
          <div>
            { expansionToggle(isExpanded) }
            <div className={`auction-status auction-status--${messagePayload.status}`}>
              {messagePayload.status}
            </div>
            { _.map(messagePayload.vessels, (vessel) => {
              return(
                <span key={vessel.id}>{vessel.name} <span className="has-text-gray-3">({vessel.imo})</span></span>
              );
            })}
            { unseenMessageCount(messagePayload.unseen_messages) }
          </div>
          { renderConversations(messagePayload, isExpanded) }
        </li>
      )
    }

    const renderMessagesInterface = (messagePayloads) => {
      return (
        <ul className="messaging__top-context">
          <li className="messaging__top-context__selector">Select an Auction</li>
          { _.map(messagePayloads, (messagePayload) => {
            return renderExpandableAuctionMessagePayload(messagePayload, expandedAuction == messagePayload.auction_id)
          })}
        </ul>
      );
    }

    const unseenMessagesEnvelope = (unseenMessageCount) => {
      if (unseenMessageCount > 0) {
        return (
          <div className="messaging__notifications messaging__notifications--has-unseen">
            <i className="fas fa-envelope has-margin-right-sm"></i>
            <span>{unseenMessageCount}</span>
          </div>
        )
      } else {
        return (
          <div className="messaging__notifications">
            <i className="fas fa-envelope has-margin-right-sm"></i>
          </div>
        )
      }
    }

    return (
      <div className={`messaging ${messagePanelIsExpanded ? "open" : "closed"}`}>
        <div className="messaging__notification-context qa-auction-messages">
          <div className="messaging__menu-bar" onClick={toggleExpanded.bind(this, 'messagePanelIsExpanded', null)}>
            <h1 className="messaging__menu-bar__title">Messages</h1>
            { unseenMessagesEnvelope(_.chain(messagePayloads).map('unseen_messages').sum().value()) }
          </div>
          <div className="qa-auction-messages-auctions">
            {messagePanelIsExpanded && renderMessagesInterface(messagePayloads)}
          </div>
        </div>
      </div>
    );
  }
};

export default Messages;
