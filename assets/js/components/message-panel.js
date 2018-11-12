import _ from 'lodash';
import React from 'react';
import moment from 'moment';

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

  setMessage(event) {
    this.setState({newMessage: event.target.value})
  }

  render() {
    const {auctionId, recipientCompany, connection, messages, sendMessage} = this.props;
    const newMessage = this.state.newMessage;
    const renderSendButton = () => {
      if (connection) {
        return (
          <button
            value='Send'
            className='button is-turquoise'
            onClick={sendMessage.bind(this, auctionId, recipientCompany, newMessage)}
          >Send</button>
        )
      } else {
        return (
          <button
            value='Send'
            className='button is-disabled'
            disabled
          >Send</button>
        )
      }
    }

    return (
      <div className='messaging__message-container'>
        { _.map(messages, (message) => {
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
        })}
        <div className="messaging__input">
          <div className="field has-addons">
            <div className="control">
              <input className="input" placeholder='Type message here' value={newMessage} onChange={this.setMessage.bind(this)} />
            </div>
            <div className="control">
              {renderSendButton()}
            </div>
          </div>
        </div>
      </div>
    );
  }
}
