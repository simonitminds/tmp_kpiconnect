import thunk from 'redux-thunk';
import fetch from 'isomorphic-fetch';
import { polyfill } from 'es6-promise';
import socket from "./socket";

import { RECEIVE_AUCTIONS, UPDATE_AUCTION_STATE } from "./constants/auctions";


let channel;
if(window.userToken && window.userToken != "" && window.userId && window.userId != "") {
  channel = socket.channel(`user_auctions:${window.userId}`, {token: window.userToken});
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
