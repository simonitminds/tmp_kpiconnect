import _ from 'lodash';
import messagesReducer, {
  initialState
} from '../../js/reducers/messages';
import {
  EXPAND_CONVERSATION,
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

describe('expand_conversation', ()=> {
  test('replaces expanded conversation', ()=> {
    const state = Object.assign({}, initialState, {
      expandedConversation: '2-Company-1'
    });
    const action = {
      type: EXPAND_CONVERSATION,
      conversation: { id: '1-Company-0' }
    }
    const output = messagesReducer(state, action);

    expect(output.expandedConversation).toEqual('1-Company-0');
  });
});
