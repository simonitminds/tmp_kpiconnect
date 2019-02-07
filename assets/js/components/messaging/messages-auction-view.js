import _ from 'lodash';
import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import MessagesAuctionHeader from './messages-auction-header';
import MessagesConversationHeader from './messages-conversation-header';
import MessagesConversationView from './messages-conversation-view';
import MessagePanel from './message-panel';


const MessagesAuctionView = ({ messagePayloads, selectedAuction, auctionState, actions, connection }) => {
  const {
    collapseMessagesAuction,
    expandMessagesConversation
  } = actions;
  const { selectedConversation } = auctionState;


  const messagePayload = _.find(messagePayloads, {auction_id: selectedAuction});
  const conversationPayload = _.find(messagePayload.conversations, {company_name: selectedConversation});

  return (
    <div className="messaging__context-list__container">
      <div className="messaging__back-indicator" onClick={() => collapseMessagesAuction(selectedAuction)}>
        <FontAwesomeIcon icon="angle-left" className="has-margin-right-sm" /> Select
      </div>

      <ul>
        <li className="messaging__context-list__auction">
          <MessagesAuctionHeader payload={messagePayload} />
        </li>
      </ul>

      { conversationPayload
        ?  <MessagePanel
              conversationPayload={conversationPayload}
              auctionId={messagePayload.auction_id}
              connection={connection}
              actions={actions}
            />
        : <ul className="messaging__context-list qa-conversations">
            <li className="messaging__context-list__selector"><span>Select a Conversation</span></li>
            {
              _.map(messagePayload.conversations, (conversation) => {
                return (
                  <li key={conversation.company_name}>
                    <MessagesConversationHeader conversation={conversation} onSelect={() => expandMessagesConversation(selectedAuction, conversation.company_name)} />
                  </li>
                );
              })
            }
          </ul>
      }
    </div>
  );
}

export default MessagesAuctionView;
