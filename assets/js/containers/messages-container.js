import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import Messages from '../components/auction/messages.js'
import { subscribeToMessageUpdates, sendMessage, toggleExpanded } from '../actions';

const mapStateToProps = (state) => {
  return {
    connection: state.messagesReducer.connection,
    expandedAuction: state.messagesReducer.expandedAuction,
    expandedConversation: state.messagesReducer.expandedConversation,
    loading: state.messagesReducer.loading,
    messagePanelIsExpanded: state.messagesReducer.messagePanelIsExpanded,
    messagePayloads: state.messagesReducer.messagePayloads
  }
};

const mapDispatchToProps = (dispatch) => ({
  dispatch,
  ...bindActionCreators({ sendMessage, toggleExpanded }, dispatch)
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
