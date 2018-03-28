import _ from "lodash";
import thunk from 'redux-thunk';
import fetch from 'isomorphic-fetch';
import { polyfill } from 'es6-promise';
import socket from "./socket";

import {
  RECEIVE_AUCTION_PAYLOADS,
  RECEIVE_AUCTION_FORM_DATA,
  UPDATE_AUCTION_PAYLOAD,
  UPDATE_DATE,
  UPDATE_INFORMATION,
  TOGGLE_SUPPLIER,
  SELECT_ALL_SUPPLIERS,
  DESELECT_ALL_SUPPLIERS,
  SELECT_PORT,
  RECEIVE_SUPPLIERS
} from "./constants";

let channel;
if(window.userToken && window.userToken != "" && window.companyId && window.companyId != "") {
  channel = socket.channel(`user_auctions:${window.companyId}`, {token: window.userToken});
};

const defaultHeaders = {
  'Accept': 'application/json',
  'Content-Type': 'application/json',
  'Authorization': `Bearer ${window.userToken}`,
  'x-expires': window.expiration
};

export function subscribeToAuctionUpdates() {
  return dispatch => {
    channel.join()
      .receive("ok", resp => { console.log("Joined successful", resp); })
      .receive("error", resp => { console.log("Unable to join", resp); });

    channel.on("auctions_update", payload => {
      dispatch({type: UPDATE_AUCTION_PAYLOAD, auctionPayload: payload});
    });
  };
}

export function getAllAuctionPayloads() {
  return dispatch => {
    fetch('/api/auctions', { headers: defaultHeaders })
      .then(checkStatus)
      .then(parseJSON)
      .then((response) => {
        return dispatch(receiveAuctionPayloads(response.data));
      });
  };
}

export function selectPort(event) {
  const port_id = event.target.value;
  return dispatch => {
    fetch(`/api/ports/${port_id}/suppliers`, { headers: defaultHeaders })
      .then(checkStatus)
      .then(parseJSON)
      .then((response) => {
        return dispatch(receiveSuppliers(port_id, response.data));
      });
  };
}

export function submitBid(auctionId, bidData) {
  return dispatch => {
    fetch(`/api/auctions/${auctionId}/bids`, {
      headers: defaultHeaders,
      method: 'POST',
      body: JSON.stringify(bidData)
    })
      .then(checkStatus)
      .then(parseJSON)
      .then((response) => {
        return console.log(response);
      });
  };
}

export function selectBid(auctionId, bidId) {
  return dispatch => {
    fetch(`/api/auctions/${auctionId}/bids/${bidId}/select`, {
      headers: defaultHeaders,
      method: 'POST',
      body: JSON.stringify({'comment': ''})
    })
      .then(checkStatus)
      .then(parseJSON)
      .then((response) => {
        return console.log(response);
      });
  };
}

export function receiveAuctionPayloads(auctionPayloads) {
  return {type: RECEIVE_AUCTION_PAYLOADS,
          auctionPayloads: auctionPayloads};
}

export function receiveSuppliers(port, suppliers) {
  return {type: RECEIVE_SUPPLIERS,
          port: port,
          suppliers: suppliers};
}

export function receiveAuctionFormData(auction, suppliers, fuels, ports, vessels) {
  return {type: RECEIVE_AUCTION_FORM_DATA,
          data: {
            auction,
            suppliers,
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
export function toggleSupplier(supplier_id) {
  return {
           type: TOGGLE_SUPPLIER,
           data: {supplier_id: supplier_id}
         };
}
export function selectAllSuppliers() {
  return {
    type: SELECT_ALL_SUPPLIERS
  };
}
export function deselectAllSuppliers() {
  return {
    type: DESELECT_ALL_SUPPLIERS
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
