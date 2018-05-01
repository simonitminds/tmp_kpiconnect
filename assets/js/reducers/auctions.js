import _ from "lodash";
import { replaceListItem } from "../utilities";
import {
  CHANNEL_CONNECTED,
  CHANNEL_DISCONNECTED,
  RECEIVE_AUCTION_PAYLOADS,
  UPDATE_AUCTION_PAYLOAD
} from "../constants";

const initialState = {
  auctionPayloads: [],
  connection: false,
  loading: true
};

export default function(state, action) {
  switch(action.type) {
    case RECEIVE_AUCTION_PAYLOADS: {
      if(_.isEmpty(action.auctionPayloads)) {
        return state;
      } else {
        return {
          ...state,
          auctionPayloads: action.auctionPayloads,
          loading: false
        };
      }
    }
    case UPDATE_AUCTION_PAYLOAD: {
      const origAuctionPayload = _.chain(state.auctionPayloads)
            .filter(['auction.id', action.auctionPayload.auction.id])
            .first()
            .value();
      const newAuctionPayloadList = replaceListItem(
        state.auctionPayloads,
        origAuctionPayload,
        action.auctionPayload
      );
      return {
        ...state,
        auctionPayloads: newAuctionPayloadList,
        loading: false
      };
    }
    case CHANNEL_CONNECTED: {
      return {
        ...state,
        connection: true
      };
    }
    case CHANNEL_DISCONNECTED: {
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
