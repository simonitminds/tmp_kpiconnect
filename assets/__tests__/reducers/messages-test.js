import _ from 'lodash';
import messagesReducer, {
  initialState
} from '../../js/reducers/messages';
import {
  TOGGLE_EXPANDED,
  UPDATE_MESSAGE_PAYLOAD
} from '../../js/constants';

const initialPayload = [
  {
    auction_id: 1,
    status: 'open',
    vessels: [],
    conversations: [
      {
        company_name: 'Company-0',
        messages: [
          {
            id: 1,
            content: 'Hello!',
            from_me: true,
            has_been_seen: true
          }, {
            id: 2,
            content: 'Zup?',
            from_me: false,
            has_been_seen: false
          }
        ]
      },
      {
        company_name: 'Company-1',
        messages: []
      }
    ]
  }, {
    auction_id: 2,
    status: 'pending',
    vessels: [],
    conversations: [
      {
        company_name: 'Company-1',
        messages: []
      }
    ]
  }
]

test('update_message_payload replaces the payload', ()=> {
  const state = Object.assign({}, initialState, {
    messagePayloads: initialPayload
  });
  const action = {
    type: UPDATE_MESSAGE_PAYLOAD,
    messagePayloads: [
      {
        auction_id: 2,
        status: 'open',
        vessels: [],
        conversations: []
      }
    ]
  }
  const output = messagesReducer(state, action);

  expect(output.messagePayloads).toEqual(action.messagePayloads);
});

describe('toggle_expanded', ()=> {
  test('toggles message panel expansion', ()=> {
    const action = {
      type: TOGGLE_EXPANDED,
      expandedItem: 'messagePanelIsExpanded',
      value: null
    }
    const output = messagesReducer(initialState, action);

    expect(output.messagePanelIsExpanded).toEqual(true);
  });

  test('toggles expanded auction', ()=> {
    const state = Object.assign({}, initialState, {
      expandedAuction: 1,
      expandedConversation: 'Company-1'
    });
    const action = {
      type: TOGGLE_EXPANDED,
      expandedItem: 'expandedAuction',
      value: 2
    }
    const output = messagesReducer(state, action);

    expect(output.expandedAuction).toEqual(2);
    expect(output.expandedConversation).toEqual(null);
  });

  test('toggles expanded conversation', ()=> {
    const state = Object.assign({}, initialState, {
      expandedAuction: 1,
      expandedConversation: 'Company-1'
    });
    const action = {
      type: TOGGLE_EXPANDED,
      expandedItem: 'expandedConversation',
      value: 'Company-2'
    }
    const output = messagesReducer(state, action);

    expect(output.expandedAuction).toEqual(1);
    expect(output.expandedConversation).toEqual('Company-2');
  });
});
