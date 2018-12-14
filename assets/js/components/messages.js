import _ from 'lodash';
import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import CollapsibleSection from './auction/collapsible-section';
import MessagesAuctionView from './messaging/messages-auction-view';
import MessagesAuctionHeader from './messaging/messages-auction-header';

class Messages extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      panelIsExpanded: false
    };
  }

  componentDidUpdate() {
    const messageBody = document.querySelector('.messaging__message-container__list');

    if(messageBody) {
      messageBody.scrollTop = messageBody.scrollHeight - messageBody.clientHeight;
    }
  }

  togglePanelExpanded() {
    this.setState({
      panelIsExpanded: !this.state.panelIsExpanded
    });
  }


  render() {
    const {
      connection,
      messagePayloads,
      actions,
      auctionStates,
      selectedAuction
    } = this.props;
    const { expandMessagesAuction } = actions;
    const { panelIsExpanded } = this.state;
    const auctionState = auctionStates[selectedAuction];

    const unseenMessageCount = _.chain(messagePayloads).map('unseen_messages').sum().value();
    const hasUnseen = unseenMessageCount > 0;

    const togglePanelExpanded = this.togglePanelExpanded.bind(this);

    const sortedMessagePayloads = _.chain(messagePayloads)
      .sortBy((payload) => {
        const statusIndex = _.indexOf(["decision", "open", "pending", "closed", "canceled", "expired"], payload.status);
        return [statusIndex, payload.id];
      })
      .value();

    return (
      <div className={`messaging ${panelIsExpanded ? "open" : "closed"}`}>
        <div className="messaging__notification-context qa-auction-messages">
          <div className="messaging__menu-bar" onClick={togglePanelExpanded}>
            <h1 className="messaging__menu-bar__title">Messages</h1>

            <div className={`messaging__notifications messaging__notifications--menu-bar ${hasUnseen ? 'messaging__notifications--has-unseen' : ''}`}>
              <FontAwesomeIcon icon="envelope" className="has-margin-right-sm" />
              { hasUnseen &&
                <span>{unseenMessageCount}</span>
              }
            </div>
          </div>
          { auctionState
            ? <MessagesAuctionView
                messagePayloads={messagePayloads}
                selectedAuction={selectedAuction}
                auctionState={auctionState}
                actions={actions}
                connection={connection}
              />
            : <div className="qa-auction-messages-auctions overflow--auto">
                { panelIsExpanded &&
                  <ul className="messaging__top-context">
                    <li className="messaging__top-context__selector"><span>Select an Auction</span></li>
                    {
                      _.map(sortedMessagePayloads, (payload) => {
                        return (
                          <li key={payload.auction_id}>
                            <MessagesAuctionHeader payload={payload} onSelect={expandMessagesAuction} />
                          </li>
                        );
                      })
                    }
                  </ul>
                }
              </div>
          }
        </div>
      </div>
    );
  }
};

export default Messages;
