// import thunk from 'redux-thunk';
import fetch from 'isomorphic-fetch';
import { polyfill } from 'es6-promise';
import socket from "./socket";

import { RECEIVE_AUCTIONS } from "./constants/auctions";

let channel = socket.channel("auctions:lobby", {});

const defaultHeaders = {
  Accept: 'application/json',
  'Content-Type': 'application/json'
};


export function subscribeToAuctionUpdates() {
  return dispatch => {
    channel.join()
      .receive("ok", resp => { console.log("Joined successfully", resp); })
      .receive("error", resp => { console.log("Unable to join", resp); });

    channel.on("auction_updated", payload => {
      console.log(payload);
    });
  };
}

export function getAllAuctions() {
  return dispatch => {
    fetch('api/auctions', { headers: defaultHeaders })
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
