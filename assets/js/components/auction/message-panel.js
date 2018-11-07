import _ from 'lodash';
import React from 'react';

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
    return (
      <div className='message__message-container'>
        { _.map(messages, (message) => {
          return (
            <div key={message.id} className={`message__message ${message.author_is_me ? 'message__message--self' : ''}`}>
              <div className='message__message__bubble'>{message.content}</div>
              <div className='message__message__timestamp'>
                <div className='message__message__timestamp__name'>
                  <strong>{message.user}</strong>
                </div>
                <div className='message__message__timestamp__time'>
                  <strong className='inline-block has-margin-left-auto'>{message.inserted_at}</strong>
                </div>
              </div>
            </div>
          )
        })}
        <input placeholder='Type message here' value={newMessage} onChange={this.setMessage.bind(this)} />
        <button
          value='Send'
          className='button is-turquoise'
          onClick={sendMessage.bind(this, auctionId, recipientCompany, newMessage)}
        >Send</button>
      </div>
    );
  }
}
