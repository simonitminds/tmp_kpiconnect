import _ from "lodash";
import { replaceListItem } from "../utilities";
import {
  MESSAGING_CHANNEL_CONNECTED,
  MESSAGING_CHANNEL_DISCONNECTED,
  RECEIVE_MESSAGE_PAYLOADS,
  UPDATE_MESSAGE_PAYLOAD
} from "../constants";

const initialState = {
  messagingPayloads: [],
  connection: false,
  loading: true
};

let newAuctionPayloadList;
let updatedAuctionPayload;

export default function(state, action) {
  switch(action.type) {
    case RECEIVE_MESSAGE_PAYLOADS: {
      if(_.isEmpty(action.messagingPayloads)) {
        return state;
      } else {
        return {
          ...state,
          messagingPayloads: action.messagingPayloads,
          loading: false
        };
      }
    }
    case UPDATE_MESSAGE_PAYLOAD: {
      // const origAuctionPayload = _.chain(state.messagingPayloads)
      //       .filter(['auction.id', action.messagingPayload.auction.id])
      //       .first()
      //       .value();
      // if (origAuctionPayload) {
      //   updatedAuctionPayload = {
      //     ...action.messagingPayload,
      //     success: origAuctionPayload.success,
      //     message: origAuctionPayload.message
      //   };
      //   newAuctionPayloadList = replaceListItem(
      //     state.messagingPayloads,
      //     origAuctionPayload,
      //     updatedAuctionPayload
      //   );
      // } else {
      //   newAuctionPayloadList = _.concat(state.messagingPayloads, action.messagingPayload);
      // }
      return {
        ...state,
        messagingPayloads: action.messagingPayloads,
        loading: false
      };
    }
    case MESSAGING_CHANNEL_CONNECTED: {
      return {
        ...state,
        connection: true
      };
    }
    case MESSAGING_CHANNEL_DISCONNECTED: {
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
