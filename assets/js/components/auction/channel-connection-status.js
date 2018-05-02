import React from 'react';

const ChannelConnectionStatus = ({connection}) => {
  const statusDisplay = () => {
    if (connection) {
      return <span className="qa-channel-connected"></span>;
    } else {
      return <span className="qa-channel-disconnected"></span>;
    }
  };

  return(
    <div>
      {statusDisplay()} Live Updates
    </div>
  );
};

export default ChannelConnectionStatus;
