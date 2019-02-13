import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

const ChannelConnectionStatus = ({connection}) => {
  const statusDisplay = () => {
    if (connection) {
      return (
        <div className="qa-channel-connected tag is-rounded is-success"><FontAwesomeIcon icon="wifi" /></div>
      )
    } else {
      return (
        <div className="qa-channel-disconnected tag is-rounded is-danger"><FontAwesomeIcon icon="wifi" /></div>
      )
    }
  };

  return(
    <div className="auction-header__connection-button">
      {statusDisplay()}
    </div>
  );
};

export default ChannelConnectionStatus;
