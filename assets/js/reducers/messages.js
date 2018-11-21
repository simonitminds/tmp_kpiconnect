import _ from "lodash";
import { replaceListItem } from "../utilities";
import { markMessagesAsSeen } from '../actions';
import {
  MESSAGE_CHANNEL_CONNECTED,
  MESSAGE_CHANNEL_DISCONNECTED,
  EXPAND_MESSAGES_AUCTION,
  EXPAND_MESSAGES_CONVERSATION,
  COLLAPSE_MESSAGES_AUCTION,
  COLLAPSE_MESSAGES_CONVERSATION,
  UPDATE_MESSAGE_PAYLOAD
} from "../constants";

export const initialState = {
  connection: false,
  loading: true,
  messagePanelIsExpanded: false,
  selectedAuction: null,
  auctionStates: {},
  messagePayloads: []
};

function maybeMarkSeenMessages(state, auctionId, companyName) {
  const conversation = _.chain(state.messagePayloads)
    .filter(['auction_id', auctionId])
    .first()
    .get('conversations')
    .filter(['company_name', companyName])
    .first()
    .value()
  if (conversation && conversation.unseen_messages > 0) {
    const unseenMessageIds = _.chain(conversation.messages)
      .filter(['has_been_seen', false])
      .filter(['author_is_me', false])
      .map('id')
      .value()
    markMessagesAsSeen(unseenMessageIds)
  }
}

export default function(state, action) {
  switch(action.type) {
    case MESSAGE_CHANNEL_CONNECTED: {
      return {
        ...state,
        connection: true
      };
    }

    case MESSAGE_CHANNEL_DISCONNECTED: {
      return {
        ...state,
        connection: false
      };
    }

    case EXPAND_MESSAGES_AUCTION: {
      const {auctionId} = action;
      const auctionState = state.auctionStates[auctionId] || {selectedConversation: null};
      return {
        ...state,
        selectedAuction: auctionId,
        auctionStates: {
          ...state.auctionStates,
          [auctionId]: auctionState
        }
      };
    }

    case COLLAPSE_MESSAGES_AUCTION: {
      return {
        ...state,
        selectedAuction: null
      };
    }

    case EXPAND_MESSAGES_CONVERSATION: {
      const {auctionId, conversation} = action;

      return {
        ...state,
        auctionStates: {
          ...state.auctionStates,
          [auctionId]: {
            ...state.auctionStates[auctionId],
            selectedConversation: conversation
          }
        }
      };
    }

    case COLLAPSE_MESSAGES_CONVERSATION: {
      const {auctionId} = action;

      return {
        ...state,
        auctionStates: {
          ...state.auctionStates,
          [auctionId]: {
            ...state.auctionStates[auctionId],
            selectedConversation: null
          }
        }
      };
    }

    case UPDATE_MESSAGE_PAYLOAD: {
      if(_.isEmpty(action.messagePayloads)) {
        return state;
      } else {
        const updatedState = {
          ...state,
          messagePayloads: action.messagePayloads,
          loading: false
        }
        return updatedState;
      }
    }

    default: {
      return state || initialState;
    }
  }
}
