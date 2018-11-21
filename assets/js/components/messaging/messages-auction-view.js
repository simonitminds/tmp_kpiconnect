import _ from 'lodash';
import React from 'react';
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


  const auctionPayload = _.find(messagePayloads, {auction_id: selectedAuction});
  const conversationPayload = _.find(auctionPayload.conversations, {company_name: selectedConversation});

  return (
    <div>
      <div>
        <div className="back-indicator has-padding-left-md has-padding-bottom-md" onClick={() => collapseMessagesAuction(selectedAuction)}>
          <i className="fas fa-angle-left has-margin-right-sm"></i> Go Back
        </div>

        <ul>
          <li>
            <MessagesAuctionHeader payload={auctionPayload} />
          </li>
        </ul>

        { conversationPayload
          ? <div>
              <MessagePanel
                conversationPayload={conversationPayload}
                auctionId={auctionPayload.auction_id}
                connection={connection}
                actions={actions}
              />
            </div>
          : <ul className="messaging__context-list qa-conversations">
              <li className="messaging__context-list__selector">Select a Conversation</li>
              {
                _.map(auctionPayload.conversations, (conversation) => {
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
    </div>
  );
}

export default MessagesAuctionView;
