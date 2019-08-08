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
  RECEIVE_FINALIZED_AUCTION_PAYLOADS,
  RECEIVE_FIXTURE_PAYLOADS,
  RECEIVE_FIXTURE_EVENT_PAYLOAD,
  RECEIVE_DELIVERED_FIXTURE,
  RECEIVE_COMPANY_BARGES,
  RECEIVE_SUPPLIERS,
  SELECT_ALL_SUPPLIERS,
  SELECT_AUCTION_TYPE,
  SELECT_PORT,
  EXPAND_MESSAGES_AUCTION,
  EXPAND_MESSAGES_CONVERSATION,
  COLLAPSE_MESSAGES_AUCTION,
  COLLAPSE_MESSAGES_CONVERSATION,
  TOGGLE_SUPPLIER,
  UPDATE_AUCTION_PAYLOAD,
  UPDATE_BID_STATUS,
  UPDATE_DATE,
  UPDATE_MONTH,
  UPDATE_INFORMATION,
  UPDATE_MESSAGE_PAYLOAD
} from "./constants";

let auctionChannel, connection, messageChannel, socket;
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

export function subscribeToAuctionUpdates(dispatchAction) {
  return (dispatch, getState) => {
    auctionChannel.join()
      .receive("ok", resp => {
        console.log("Joined successful", resp);
        dispatch({type: AUCTION_CHANNEL_CONNECTED});
        dispatch(dispatchAction());
      })
      .receive("error", resp => { console.log("Unable to join", resp); });

    auctionChannel.on("auctions_update", payload => {
      dispatch({type: UPDATE_AUCTION_PAYLOAD, auctionPayload: payload});
    });

    auctionChannel.onError( () => {
      connection = getState().auctionsReducer.connection;
      if (connection) {dispatch({type: AUCTION_CHANNEL_DISCONNECTED})};
    });
  };
}

export function subscribeToMessageUpdates() {
  return (dispatch, getState) => {
    messageChannel.join()
      .receive("ok", resp => {
        console.log("Joined chat successfully", resp);
        dispatch({type: MESSAGE_CHANNEL_CONNECTED});
      })
      .receive("error", resp => { console.log("Unable to join", resp); });

    messageChannel.on("messages_update", payload => {
      dispatch({type: UPDATE_MESSAGE_PAYLOAD, messagePayloads: payload.message_payloads});
    });

    messageChannel.onError( () => {
      connection = getState().messagesReducer.connection;
      if (connection) {dispatch({type: MESSAGE_CHANNEL_DISCONNECTED})};
    });
  };
}

export function expandMessagesAuction(auctionId, value) {
  return {type: EXPAND_MESSAGES_AUCTION,
          auctionId};
}

export function expandMessagesConversation(auctionId, conversation, value) {
  return {type: EXPAND_MESSAGES_CONVERSATION,
          auctionId,
          conversation};
}
export function collapseMessagesAuction(auctionId, value) {
  return {type: COLLAPSE_MESSAGES_AUCTION,
          auctionId};
}

export function collapseMessagesConversation(auctionId, conversation, value) {
  return {type: COLLAPSE_MESSAGES_CONVERSATION,
          auctionId,
          conversation};
}

export function markMessagesAsSeen(messageIds) {
  messageChannel.push('seen', {ids: messageIds})
}

export function sendMessage(auctionId, recipientCompany, content) {
  return dispatch => {
    messageChannel.push('send', {auctionId: auctionId, recipient: recipientCompany, content: content})
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

export function getAllFinalizedAuctionPayloads() {
  return dispatch => {
    fetch('/api/historical_auctions', { headers: defaultHeaders })
      .then(checkStatus)
      .then(parseJSON)
      .then((response) => {
        return dispatch(receiveFinalizedAuctionPayloads(response.data));
      });
  };
}

export function getAllFixturePayloads() {
  return dispatch => {
    fetch('/api/auction_fixtures', { headers: defaultHeaders })
      .then(checkStatus)
      .then(parseJSON)
      .then((response) => {
        return dispatch(receiveFixturePayloads(response.data))
      });
  }
}

export function getAuctionPayload(auctionId) {
  return dispatch => {
    fetch(`/api/auctions/${auctionId}`, { headers: defaultHeaders })
      .then(checkStatus)
      .then(parseJSON)
      .then((response) => {
        return dispatch(receiveAuctionPayloads([response.data]));
      });
  };
}

export function getFixtureEventPayload(fixtureId) {
  return dispatch => {
    fetch(`/api/auction_fixtures/${fixtureId}/events`, { headers: defaultHeaders })
      .then(checkStatus)
      .then(parseJSON)
      .then((response) => {
        return dispatch(receiveFixtureEventPayload(response))
      })
  }
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

export function inviteObserverToAuction(auctionId, userId) {
  return dispatch => {
    fetch(`/api/auctions/${auctionId}/observers/${userId}/invite`, {
      headers: defaultHeaders,
      method: 'POST'
    })
    .then(checkStatus)
    .then(parseJSON)
    .then((response) => {
      dispatch({type: UPDATE_AUCTION_PAYLOAD, auctionPayload: response});
    })
  }
}

export function uninviteObserverFromAuction(auctionId, userId) {
  return dispatch => {
    fetch(`/api/auctions/${auctionId}/observers/${userId}/invite`, {
      headers: defaultHeaders,
      method: 'POST'
    })
    .then(checkStatus)
    .then(parseJSON)
    .then((response) => {
      dispatch({type: UPDATE_AUCTION_PAYLOAD, auctionPayload: response})
    })
  }
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

export function submitComment(auctionId, comment) {
  return dispatch => {
    fetch(`/api/auctions/${auctionId}/comments`, {
      headers: defaultHeaders,
      method: 'POST',
      body: JSON.stringify(comment)
    })
    .then(checkStatus)
    .then(parseJSON)
  };
}

export function unsubmitComment(auctionId, commentId) {
  return dispatch => {
    fetch(`/api/auctions/${auctionId}/comments/${commentId}`, {
      headers: defaultHeaders,
      method: 'DELETE',
    })
    .then(checkStatus)
    .then(parseJSON)
  }
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

export function deliverAuctionFixture(auctionId, fixtureId, delivered) {
  return dispatch => {
    fetch(`/api/auctions/${auctionId}/fixtures/${fixtureId}/deliver`, {
      headers: defaultHeaders,
      method: 'POST',
      body: JSON.stringify(delivered)
    })
      .then(checkStatus)
      .then(parseJSON)
      .then((fixture) => {
        return dispatch(receiveDeliveredFixture(fixture));
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

export function receiveFinalizedAuctionPayloads(auctionPayloads) {
  return {type: RECEIVE_FINALIZED_AUCTION_PAYLOADS,
          auctionPayloads: auctionPayloads};
}

export function receiveFixturePayloads(fixturePayloads) {
  return {type: RECEIVE_FIXTURE_PAYLOADS,
          fixturePayloads: fixturePayloads};
}

export function receiveFixtureEventPayload(fixtureEventPayload) {
  return {type: RECEIVE_FIXTURE_EVENT_PAYLOAD,
          fixtureEventPayload: fixtureEventPayload};
}

export function receiveDeliveredFixture(data) {
  const {data: fixture} = data;
  return {type: RECEIVE_DELIVERED_FIXTURE,
          deliveredFixture: fixture};
}

export function receiveSuppliers(port, suppliers) {
  return {type: RECEIVE_SUPPLIERS,
          port: port,
          suppliers: suppliers};
}

export function receiveFilteredPayloads(payloads) {
  return {type: RECEIVE_FILTERED_PAYLOADS,
          auctionPayloads: payloads};
}

export function receiveAuctionFormData(auction, suppliers, fuels, fuel_indexes, ports, vessels, credit_margin_amount) {
  return {type: RECEIVE_AUCTION_FORM_DATA,
          data: {
            auction,
            suppliers,
            fuels,
            fuel_indexes,
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

export function updateMonth(property, value) {
  return {type: UPDATE_MONTH,
          data: {
            property,
            'value': _.get(value, 'target.value', value)
          }
        };
}

export function selectAuctionType(event) {
  const auctionType = event.target.value;
  return {
           type: SELECT_AUCTION_TYPE,
           data: {type: auctionType}
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
  if (response.status >= 200 && response.status < 300 || response.status == 422) {
    return response;
  } else {
    throw response;
  }
}

function parseJSON(response) {
  return response.json();
}
