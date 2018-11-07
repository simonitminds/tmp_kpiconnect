import _ from "lodash";
import { replaceListItem } from "../utilities";
import {
  MESSAGE_CHANNEL_CONNECTED,
  MESSAGE_CHANNEL_DISCONNECTED,
  TOGGLE_EXPANDED,
  UPDATE_MESSAGE_PAYLOAD
} from "../constants";

export const initialState = {
  connection: false,
  expandedAuction: null,
  expandedConversation: null,
  loading: true,
  messagePanelIsExpanded: false,
  messagePayloads: []
};

export default function(state, action) {
  switch(action.type) {
    case TOGGLE_EXPANDED: {
      const expandedItem = action.expandedItem;
      const value = action.value;
      if (expandedItem === 'messagePanelIsExpanded') {
        return {
          ...state,
          [expandedItem]: !state.messagePanelIsExpanded
        }
      }
      if (expandedItem === 'expandedAuction' && state.expandedAuction != value) {
        return {
          ...state,
          [expandedItem]: value,
          expandedConversation: null
        }
      }
      if (expandedItem === 'expandedConversation' && state.expandedConversation != value) {
        return {
          ...state,
          [expandedItem]: value
        }
      }
      return state
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
