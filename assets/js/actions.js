import _ from "lodash";
import {Socket} from "phoenix"
import thunk from 'redux-thunk';
import fetch from 'isomorphic-fetch';
import { polyfill } from 'es6-promise';
import {
  AUCTION_CHANNEL_CONNECTED,
  AUCTION_CHANNEL_DISCONNECTED,
  DESELECT_ALL_SUPPLIERS,
  MESSAGE_CHANNEL_CONNECTED,
  MESSAGE_CHANNEL_DISCONNECTED,
  RECEIVE_AUCTION_FORM_DATA,
  RECEIVE_AUCTION_PAYLOADS,
  RECEIVE_COMPANY_BARGES,
  RECEIVE_MESSAGE_PAYLOADS,
  RECEIVE_SUPPLIERS,
  SELECT_ALL_SUPPLIERS,
  SELECT_PORT,
  TOGGLE_SUPPLIER,
  UPDATE_AUCTION_PAYLOAD,
  UPDATE_BID_STATUS,
  UPDATE_DATE,
  UPDATE_INFORMATION,
  UPDATE_MESSAGE_PAYLOAD
} from "./constants";

let auctionChannel, messageChannel, socket;
if(window.userToken && window.userToken != "" && window.companyId && window.companyId != "") {
  socket = new Socket("/socket", {params: {token: window.userToken}});
  socket.connect();

  auctionChannel = socket.channel(`user_auctions:${window.companyId}`, {token: window.userToken});
  messageChannel = socket.channel(`user_messages:${window.companyId}`, {token: window.userToken});
};

const defaultHeaders = {
  'Accept': 'application/json',
  'Content-Type': 'application/json',
  'Authorization': `Bearer ${window.userToken}`,
  'x-expires': window.expiration
};

export function subscribeToAuctionMessages() {
  return (dispatch, getState) => {
    messageChannel.join()
      .receive("ok", resp => {
        console.log("Joined chat successfully", resp);
        dispatch({type: MESSAGE_CHANNEL_CONNECTED});
        dispatch(getAllMessagePayloads());
      })
      .receive("error", resp => { console.log("Unable to join", resp); });

    messageChannel.on("messages_update", payload => {
      dispatch({type: UPDATE_MESSAGE_PAYLOAD, messagePayloads: payload});
    });

    messageChannel.onError( () => {
      const { connection } = getState().auctionsReducer;
      if (connection) {dispatch({type: MESSAGE_CHANNEL_DISCONNECTED})};
    });
  };
}

export function subscribeToAuctionUpdates() {
  return (dispatch, getState) => {
    auctionChannel.join()
      .receive("ok", resp => {
        console.log("Joined successful", resp);
        dispatch({type: AUCTION_CHANNEL_CONNECTED});
        dispatch(getAllAuctionPayloads());
      })
      .receive("error", resp => { console.log("Unable to join", resp); });

    auctionChannel.on("auctions_update", payload => {
      dispatch({type: UPDATE_AUCTION_PAYLOAD, auctionPayload: payload});
    });

    auctionChannel.onError( () => {
      const { connection } = getState().auctionsReducer;
      if (connection) {dispatch({type: AUCTION_CHANNEL_DISCONNECTED})};
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

export function getAllMessagePayloads() {
  return dispatch => {
    fetch('/api/auctions', { headers: defaultHeaders })
      .then(checkStatus)
      .then(parseJSON)
      .then((response) => {
        return dispatch(receiveMessagePayloads(response.data));
      });
  };
}

export function getCompanyBarges(companyId) {
  return dispatch => {
    fetch(`/api/companies/${companyId}/barges`, { headers: defaultHeaders })
      .then(checkStatus)
      .then(parseJSON)
      .then((response) => {
        return dispatch(receiveCompanyBarges(response.data));
      });
  };
}

export function submitBargeForApproval(auctionId, bargeId) {
  return dispatch => {
    fetch(`/api/auctions/${auctionId}/barges/${bargeId}/submit`, {
        headers: defaultHeaders,
        method: 'POST'
      })
      .then(checkStatus)
      .then(parseJSON)
      .then((response) => {
        dispatch({type: UPDATE_AUCTION_PAYLOAD, auctionPayload: response});
      });
  };
}

export function unsubmitBargeForApproval(auctionId, bargeId) {
  return dispatch => {
    fetch(`/api/auctions/${auctionId}/barges/${bargeId}/unsubmit`, {
        headers: defaultHeaders,
        method: 'POST'
      })
      .then(checkStatus)
      .then(parseJSON)
      .then((response) => {
        dispatch({type: UPDATE_AUCTION_PAYLOAD, auctionPayload: response});
      });
  };
}

export function approveBarge(auctionId, bargeId, supplierId) {
  return dispatch => {
    fetch(`/api/auctions/${auctionId}/barges/${bargeId}/${supplierId}/approve`, {
        headers: defaultHeaders,
        method: 'POST'
      })
      .then(checkStatus)
      .then(parseJSON)
      .then((response) => {
        dispatch({type: UPDATE_AUCTION_PAYLOAD, auctionPayload: response});
      });
  };
}

export function rejectBarge(auctionId, bargeId, supplierId) {
  return dispatch => {
    fetch(`/api/auctions/${auctionId}/barges/${bargeId}/${supplierId}/reject`, {
        headers: defaultHeaders,
        method: 'POST'
      })
      .then(checkStatus)
      .then(parseJSON)
      .then((response) => {
        dispatch({type: UPDATE_AUCTION_PAYLOAD, auctionPayload: response});
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
      return dispatch(updateBidStatus(auctionId, response));
    }).catch((error) => {
      return dispatch(updateBidStatus(auctionId, {'success': false, 'message': 'No connection to server'}));
    });
  };
}

export function revokeBid(auctionId, bidData) {
  return dispatch => {
    fetch(`/api/auctions/${auctionId}/revoke_bid`, {
      headers: defaultHeaders,
      method: 'POST',
      body: JSON.stringify(bidData)
    })
    .then(checkStatus)
    .then(parseJSON)
    .then((response) => {
      return dispatch(updateBidStatus(auctionId, response));
    }).catch((error) => {
      return dispatch(updateBidStatus(auctionId, {'success': false, 'message': 'No connection to server'}));
    });
  };
}

export function acceptWinningSolution(auctionId, solution) {
  return dispatch => {
    fetch(`/api/auctions/${auctionId}/select_solution`, {
      headers: defaultHeaders,
      method: 'POST',
      body: JSON.stringify(solution)
    })
      .then(checkStatus)
      .then(parseJSON)
      .then((response) => {
        return console.log(response);
      });
  };
}

export function setPortAgent(auctionId, portAgent) {
  return dispatch => {
    fetch(`/api/auctions/${auctionId}/port_agent`, {
      headers: defaultHeaders,
      method: 'POST',
      body: JSON.stringify(portAgent)
    })
      .then(checkStatus)
      .then(parseJSON)
      .then((response) => {
        return console.log(response);
      });
  };
}


export function updateBidStatus(auctionId, response) {
  return {type: UPDATE_BID_STATUS,
          auctionId,
          success: response.success,
          message: response.message};
}

export function receiveAuctionPayloads(auctionPayloads) {
  return {type: RECEIVE_AUCTION_PAYLOADS,
          auctionPayloads: auctionPayloads};
}

export function receiveMessagePayloads(messagePayloads) {
  return {type: RECEIVE_MESSAGE_PAYLOADS,
          messagePayloads: messagePayloads};
}

export function receiveSuppliers(port, suppliers) {
  return {type: RECEIVE_SUPPLIERS,
          port: port,
          suppliers: suppliers};
}

export function receiveAuctionFormData(auction, suppliers, fuels, ports, vessels, credit_margin_amount) {
  return {type: RECEIVE_AUCTION_FORM_DATA,
          data: {
            auction,
            suppliers,
            fuels,
            ports,
            vessels,
            credit_margin_amount
          }
        };
}

export function receiveCompanyBarges(barges) {
  return {type: RECEIVE_COMPANY_BARGES,
          barges: barges};
}

export function updateInformation(property, value) {
  return {type: UPDATE_INFORMATION,
          data: {
            property,
            'value': _.get(value, 'target.value', value)
          }
        };
}

export function updateInformationFromCheckbox(property, value) {
  console.log(_.get(value, 'target.checked', value));
  return {type: UPDATE_INFORMATION,
          data: {
            property,
            'value': _.get(value, 'target.checked', value)
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
