import _ from "lodash";
import thunk from 'redux-thunk';
import fetch from 'isomorphic-fetch';
import { polyfill } from 'es6-promise';
import socket from "./socket";

import {
  RECEIVE_AUCTIONS,
  RECIEVE_AUCTION_FORM_DATA,
  UPDATE_AUCTION_STATE,
  UPDATE_DATE,
  UPDATE_INFORMATION
} from "./constants";

let channel;
if(window.userToken && window.userToken != "" && window.companyId && window.companyId != "") {
  channel = socket.channel(`user_auctions:${window.companyId}`, {token: window.userToken});
};

const defaultHeaders = {
  Accept: 'application/json',
  'Content-Type': 'application/json'
};


export function subscribeToAuctionUpdates() {
  return dispatch => {
    channel.join()
      .receive("ok", resp => { console.log("Joined successful", resp); })
      .receive("error", resp => { console.log("Unable to join", resp); });

    channel.on("auctions_update", payload => {
      dispatch({type: UPDATE_AUCTION_STATE, auction: payload});
    });
  };
}

export function getAllAuctions() {
  return dispatch => {
    fetch('/api/auctions', { headers: defaultHeaders })
      .then(checkStatus)
      .then(parseJSON)
      .then((response) => {
        return dispatch(receiveAuctions(response.data));
      });
  };
}

export function receiveAuctions(auctions) {
  return {type: RECEIVE_AUCTIONS,
          auctions: auctions};
}

export function receiveAuctionFormData(auction, fuels, ports, vessels) {
  return {type: RECIEVE_AUCTION_FORM_DATA,
          data: {
            auction,
            fuels,
            ports,
            vessels
          }
        };
}

export function updateInformation(property, value) {
  return {type: UPDATE_INFORMATION,
          data: {
            property,
            'value': _.get(value, 'target.value', value)
          }
        };
}

export function updateDate(property, value) {
  return {type: UPDATE_DATE,
          data: {
            property,
            'value': _.get(value, 'target.value', value)
          }
        };
}

function checkStatus(response) {
  if (response.status >= 200 && response.status < 300) {
    return response;
  } else {
    throw response.statusText;
  }
}

function parseJSON(response) {
  return response.json();
}
