import React from 'react';

const BidStatus = ({success, message}) => {
  const statusDisplay = () => {
    if (success) {
      return <div className="qa-auction-bid-status is-success">{message}</div>;
    } else {
      return <div className="qa-auction-bid-status is-danger">{message}</div>;
    }
  };

  return(
    <div>
      {statusDisplay()}
    </div>
  );
};

export default BidStatus;
