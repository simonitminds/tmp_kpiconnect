import React from 'react';
import _ from 'lodash';
import CollapsibleSection from './collapsible-section';
import CollapsingBarge from './collapsing-barge';

const BargeSubmission = ({auctionPayload, submitBargeForm, unsubmitBargeForm, approveBargeForm, rejectBargeForm, companyBarges, isBuyer, supplierId}) => {
  const auction = auctionPayload.auction;
  const auctionState = auctionPayload.status;
  const submittedBarges = auctionPayload.submitted_barges;
  const availableBarges = companyBarges.filter((barge) => {
    return !submittedBarges.find((submittedBarge) => submittedBarge.barge_id == barge.id)
  });

  const renderAvailableBarge = (barge) => {
    return (
      <div className={ `qa-barge-header qa-barge-${barge.id}` } key={ barge.id } >
        <CollapsingBarge
          trigger={ `${barge.name.toLowerCase()} (${barge.imo_number})` }
          classParentString="collapsing-barge__barge"
          easing="ease"
          open={false}
          submitBargeForm={submitBargeForm}
          unsubmitBargeForm={unsubmitBargeForm}
          approveBargeForm={approveBargeForm}
          rejectBargeForm={rejectBargeForm}
          auction={auction}
          barge={barge}
          supplierId={supplierId}
          bargeStatus={null}
          isBuyer={isBuyer}
        >
        </CollapsingBarge>
      </div>
    );
  };

  const renderSubmittedBarge = (auctionBarge) => {
    const barge = auctionBarge.barge;
    const approvalStatus = auctionBarge.approval_status.toLowerCase();

    return (
      <div className={ `qa-barge-${barge.id} qa-barge-status-${approvalStatus}` } key={ barge.id }>
        <CollapsingBarge
          trigger={ `${barge.name.toLowerCase()} (${barge.imo_number})` }
          classParentString="collapsing-barge__barge"
          easing="ease"
          open={false}
          submitBargeForm={submitBargeForm}
          unsubmitBargeForm={unsubmitBargeForm}
          approveBargeForm={approveBargeForm}
          rejectBargeForm={rejectBargeForm}
          auction={auction}
          supplierId={supplierId}
          barge={auctionBarge.barge}
          bargeStatus={auctionBarge.approval_status}
          isBuyer={isBuyer}
        >
        </CollapsingBarge>
      </div>
    );
  };


  return(
    <div className="box has-margin-bottom-md has-padding-bottom-none">
      <div className="box__subsection has-padding-bottom-none">
        <h3 className="box__header">Barges for Delivery</h3>
        <form className="auction-barging__container">
          { submittedBarges && submittedBarges.length > 0 && (
            <div className="has-margin-top-sm qa-submitted-barges">
              <strong>Submitted Barges</strong>
              { submittedBarges.map(renderSubmittedBarge) }
            </div>
          )}

          { availableBarges && availableBarges.length > 0 && (
            <div className="qa-available-barges">
              <strong>Available Barges</strong>
              { availableBarges.map(renderAvailableBarge) }
            </div>
          )}
        </form>
      </div>
    </div>
  );
};

export default BargeSubmission;
