import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import Messages from '../components/messages.js'
import {
  subscribeToMessageUpdates,
  sendMessage,
  expandMessagesAuction,
  expandMessagesConversation,
  collapseMessagesAuction,
  collapseMessagesConversation,
  markMessagesAsSeen
} from '../actions';

const mapStateToProps = (state) => {
  return {
    connection: state.messagesReducer.connection,
    loading: state.messagesReducer.loading,
    selectedAuction: state.messagesReducer.selectedAuction,
    auctionStates: state.messagesReducer.auctionStates,
    messagePanelIsExpanded: state.messagesReducer.messagePanelIsExpanded,
    messagePayloads: state.messagesReducer.messagePayloads
  }
};

const mapDispatchToProps = (dispatch) => ({
  dispatch,
  actions: {
    markMessagesAsSeen,
    ...bindActionCreators({
      sendMessage,
      expandMessagesAuction,
      expandMessagesConversation,
      collapseMessagesAuction,
      collapseMessagesConversation
    }, dispatch)
  }
});

export class MessagesContainer extends React.Component {
  dispatchItem() {
    this.props.dispatch(subscribeToMessageUpdates());
  }
  componentDidMount() {
    this.dispatchItem();
  }
  componentDidUpdate(prevProps) {
    if (this.props.id !== prevProps.id) {
      this.dispatchItem();
    }
  }
  render() {
    if (this.props.loading) {
      return <div className="alert is-info">Loading...</div>
    } else {
      return <Messages {...this.props}/>
    }
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(MessagesContainer);
