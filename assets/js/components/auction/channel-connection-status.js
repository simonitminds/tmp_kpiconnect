import React from 'react';

const ChannelConnectionStatus = ({connection}) => {
  const statusDisplay = () => {
    if (connection) {
      return (
        <div className="qa-channel-connected tag is-rounded is-success"><i className="fas fa-wifi"></i></div>
      )
    } else {
      return (
        <div className="qa-channel-disconnected tag is-rounded is-danger"><i className="fas fa-wifi"></i></div>
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
