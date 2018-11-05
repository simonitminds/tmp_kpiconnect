import _ from "lodash";
import { replaceListItem } from "../utilities";
import {
  EXPAND_CONVERSATION,
  MESSAGE_CHANNEL_CONNECTED,
  MESSAGE_CHANNEL_DISCONNECTED,
  UPDATE_MESSAGE_PAYLOAD
} from "../constants";

const initialState = {
  connection: false,
  expandedConversation: null,
  loading: true,
  messagePayloads: []
};

export default function(state, action) {
  switch(action.type) {
    case EXPAND_CONVERSATION: {
      return {
        ...state,
        expandedConversation: action.conversation.id
      };
    }
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
    case UPDATE_MESSAGE_PAYLOAD: {
      if(_.isEmpty(action.messagePayloads)) {
        return state;
      } else {
        return {
          ...state,
          messagePayloads: action.messagePayloads,
          loading: false
        };
      }
    }
    default: {
      return state || initialState;
    }
  }
}
