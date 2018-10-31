import _ from "lodash";
import { replaceListItem } from "../utilities";
import {
  MESSAGE_CHANNEL_CONNECTED,
  MESSAGE_CHANNEL_DISCONNECTED,
  RECEIVE_MESSAGE_PAYLOADS,
  UPDATE_MESSAGE_PAYLOAD
} from "../constants";

const initialState = {
  messagePayloads: [],
  connection: false,
  loading: true
};

let newAuctionPayloadList;
let updatedAuctionPayload;

export default function(state, action) {
  switch(action.type) {
    case RECEIVE_MESSAGE_PAYLOADS: {
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
    case UPDATE_MESSAGE_PAYLOAD: {
      // const origAuctionPayload = _.chain(state.messagePayloads)
      //       .filter(['auction.id', action.messagePayload.auction.id])
      //       .first()
      //       .value();
      // if (origAuctionPayload) {
      //   updatedAuctionPayload = {
      //     ...action.messagePayload,
      //     success: origAuctionPayload.success,
      //     message: origAuctionPayload.message
      //   };
      //   newAuctionPayloadList = replaceListItem(
      //     state.messagePayloads,
      //     origAuctionPayload,
      //     updatedAuctionPayload
      //   );
      // } else {
      //   newAuctionPayloadList = _.concat(state.messagePayloads, action.messagePayload);
      // }
      return {
        ...state,
        messagePayloads: action.messagePayloads,
        loading: false
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
    default: {
      return state || initialState;
    }
  }
}
