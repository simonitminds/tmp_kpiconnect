import React from 'react';

const ChannelConnectionStatus = ({connection}) => {
  const statusDisplay = () => {
    if (connection) {
      return (
        // <div className="qa-channel-connected control">
        //   <div className="tags has-addons">
        //     <span className="tag is-dark">Connection Status</span>
        //     <span className="tag is-success">Online</span>
        //   </div>
        // </div>
        <div className="tag is-rounded is-success"><i className="fas fa-wifi"></i></div>
      )
    } else {
      return (
        // <div className="qa-channel-disconnected control">
        //   <div className="tags has-addons">
        //     <span className="tag is-dark">Connection Status</span>
        //     <span className="tag is-danger">Offline</span>
        //   </div>
        // </div>
        <div className="tag is-rounded is-danger"><i className="fas fa-wifi"></i></div>
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
