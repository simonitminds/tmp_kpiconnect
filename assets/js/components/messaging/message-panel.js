import _ from 'lodash';
import React from 'react';
import moment from 'moment';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

export default class MessagePanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      newMessage: ""
    }
  }

  componentDidUpdate(prevProps) {
    if (this.props !== prevProps) {
      this.setState({
        newMessage: ""
      })
    }
  }

  componentDidMount() {
    this.timerID = setInterval(
      () => this.tick(),
      2000
    );
  }

  componentWillUnmount() {
    clearInterval(this.timerID);
  }

  tick() {
    const { actions, conversationPayload } = this.props;
    const unseenMessageIds = this.getUnseenMessages(conversationPayload.messages);
    if(unseenMessageIds.length > 0) {
      actions.markMessagesAsSeen(unseenMessageIds);
    }
  }


  handleMessageChange(event) {
    this.setState({newMessage: event.target.value})
  }

  submitMessage(event) {
    event.preventDefault();
    const {actions, conversationPayload, auctionId} = this.props;
    const newMessage = this.state.newMessage;
    actions.sendMessage(auctionId, conversationPayload.company_name, newMessage);
    return false;
  }

  getUnseenMessages(messages) {
    return _.chain(messages)
      .filter(['has_been_seen', false])
      .filter(['author_is_me', false])
      .map('id')
      .value();
  }

  render() {
    const { conversationPayload, connection, actions, auctionId } = this.props;
    const { collapseMessagesConversation } = actions;
    const { company_name, messages } = conversationPayload;


    const newMessage = this.state.newMessage;
    const messageHasContent = !!newMessage;
    const canSubmit = connection && messageHasContent;

    return (
      <div className='messaging__message-container'>
        <div className="messaging__message-container__header">
          <h1>{company_name}</h1>
          <div className="messaging__back-indicator" onClick={() => collapseMessagesConversation(auctionId, company_name)}>
            <FontAwesomeIcon icon="angle-left" className="has-margin-right-sm" /> Select
          </div>
        </div>
        <div className='messaging__message-container__list'>
          {
            _.map(messages, (message) => {
              return (
                <div
                  key={message.id}
                  className={`qa-message-id-${message.id} messaging__message ${message.author_is_me ? 'messaging__message--self' : ''}`}
                  data-has-been-seen={message.has_been_seen}
                >
                  <div className='messaging__message__bubble'>{message.content}</div>
                  <div className='messaging__message__timestamp'>
                    <div className='messaging__message__timestamp__name'>
                      <strong>{message.user}</strong>
                    </div>
                    <div className='messaging__message__timestamp__time'>
                      <strong className='inline-block has-margin-left-auto'>
                        {moment(message.inserted_at).format('MMM Do h:mm a')}
                      </strong>
                    </div>
                  </div>
                </div>
              )
            })
          }

          { messages.length == 0 &&
            <div className="is-gray-0 has-text-weight-normal has-padding-md has-margin-bottom-md is-italic">No messages yet.</div>
          }
        </div>

        <form onSubmit={this.submitMessage.bind(this)}>
          <div className="messaging__input">
            <div className="field has-addons">
              <div className="control">
                <input className="input" placeholder='Type message here' value={newMessage} onChange={this.handleMessageChange.bind(this)} />
              </div>

              <div className="control">
                <input
                  type="submit"
                  value='Send'
                  className={`button ${canSubmit ? 'is-turquoise' : 'is-disabled'}`}
                  disabled={!canSubmit}
                />
              </div>
            </div>
          </div>
        </form>
      </div>
    );
  }
}
