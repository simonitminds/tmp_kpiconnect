import _ from 'lodash';
import React from 'react';
import CollapsibleSection from './collapsible-section';
import MessagePanel from './message-panel';

const Messages = (props) => {
  const {
    connection,
    expandedAuction,
    expandedConversation,
    messagePanelIsExpanded,
    messagePayloads,
    sendMessage,
    toggleExpanded
  } = props;

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
    return (
      <li
        key={conversation.company_name}
        className={`qa-conversation-company-${conversation.company_name} ${isExpanded ? "open" : "closed"}`}
        onClick={toggleExpanded.bind(this, 'expandedConversation', conversation.company_name)}
      >
        <h2>
          { expansionToggle(isExpanded) }
          {conversation.company_name}
          { isExpanded && messagePanel(auctionId, conversation) }
        </h2>
      </li>
    )
  }

  const renderConversations = (messagePayload, isExpanded) => {
    if (isExpanded) {
      return (
        <ul className="qa-conversations">
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
        className={`qa-auction-${messagePayload.auction_id}-message-payloads ${isExpanded ? "open" : "closed"}`}
        onClick={toggleExpanded.bind(this, 'expandedAuction', messagePayload.auction_id)}
      >
        <h2>
          { expansionToggle(isExpanded) }
          <div className={`auction-header__status auction-header__status-${messagePayload.status} tag is-rounded has-margin-bottom-non has-margin-right-xs is-capitalized`}>
            {messagePayload.status}
          </div>
          { _.map(messagePayload.vessels, (vessel) => {
            return(
              <span key={vessel.id}>{vessel.name} <span className="has-text-gray-3">({vessel.imo})</span></span>
            );
          })}
          { renderConversations(messagePayload, isExpanded) }
        </h2>
      </li>
    )
  }

  const renderMessagesInterface = (messagePayloads) => {
    return (
      <ul className="message__context-list">
        { _.map(messagePayloads, (messagePayload) => {
          return renderExpandableAuctionMessagePayload(messagePayload, expandedAuction == messagePayload.auction_id)
        })}
      </ul>
    );
  }

  const unseenMessages = (unseenMessageCount) => {
    if (unseenMessageCount > 0) {
      return (
        <div className="message__notifications message__notifications--has-unread">
          <i className="fas fa-envelope has-margin-right-sm"> {unseenMessageCount}</i>
        </div>
      )
    } else {
      return (
        <div className="message__notifications message__notifications">
          <i className="fas fa-envelope has-margin-right-sm"></i>
        </div>
      )
    }
  }

  return (
    <div className={`message__notification-context ${messagePanelIsExpanded ? "open" : "closed"} qa-auction-messages`}>
      <div onClick={toggleExpanded.bind(this, 'messagePanelIsExpanded', null)}>
        <div className="message__menu-bar">
          <h1 className="message__menu-bar__title">Messages</h1>
          { unseenMessages(messagePayloads.unseen_messages) }
        </div>
      </div>
      <div className="message__conversation-list qa-auction-messages-auctions">
        {messagePanelIsExpanded && renderMessagesInterface(messagePayloads)}
      </div>
    </div>
  );
};

export default Messages;
