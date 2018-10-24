import _ from 'lodash';
import React from 'react';
import CollapsibleSection from './collapsible-section';

const messagingBox = document.querySelector('.messaging');
const messagingBoxCollapse = document.querySelector('.messaging__menu-bar__title');
const messagingNotifications = document.querySelector('.messaging__notifications');
const messagingContexts = [...document.querySelectorAll('.messaging > div')];
const messagingAuctionContextToggle = document.querySelector('.messaging__auction-context > .messaging__toggle');
const messagingUserContextToggle = document.querySelector('.messaging__user-context > .messaging__toggle');
const conversationBox = document.querySelector('.messaging__conversation');
// const newMessageList = document.querySelector('.messaging__notifications');

const stripOpenState = () => { messagingContexts.map( container => container.classList.remove('open'))}
const messagingBoxToggle = () => {
  messagingBox.classList.toggle('active');
}

const messagingNotificationsToggle = () => {
  messagingNotifications.parentElement.parentElement.classList.toggle('open');
}
const messagingToggle = () => {
  if(this.parentElement.classList.contains('open')) {
    // stripHiddenState();
    this.parentElement.classList.remove('open');
    conversationBox.classList.add('open');
  }
  else {
    stripOpenState();
    this.parentElement.classList.toggle('open');
  }
};

const filteredAuctionsPayloads = () => {
  return _.filter(this.props.messagingPayloads, (auctionPayload) => {
    _.includes(["pending", "open", "decision", "closed"], auctionPayload.status);
  });
}

const filteredAuctionsCount = () => {
  return filteredAuctionsPayloads().length;
}

const AuctionMessaging = ({messagingPayloads}) => {
  return(
    <div className="messaging qa-auction-messaging">
      <div className="messaging__notification-context">
        <div className="messaging__menu-bar">
          <h1 className="messaging__menu-bar__title">Messages</h1>
          <div className="messaging__notifications messaging__notifications--has-unread">
            <i className="fas fa-envelope has-margin-right-sm"></i>
          </div>
        </div>
        <div className="messaging__conversation-list">
          <CollapsibleSection
            trigger="Messages"
            classParentString="messaging__context-list qa-auction-messaging-auctions"
            contentChildCount={filteredAuctionsCount()}
            open={filteredAuctionsCount() > 0}
          />
          <ul className="messaging__context-list">
            <li className="messaging__context-list"></li>
            <li className="messaging__context-list"></li>
            <li className="messaging__context-list"></li>
          </ul>
        </div>
      </div>
    </div>
  );
};

export default AuctionMessaging;
