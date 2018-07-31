import React from 'react';
import _ from 'lodash';
import CollapsibleSection from './collapsible-section';
import CollapsingBarge from './collapsing-barge';

const BargeSubmission = ({auctionPayload, submitBargeForm, unsubmitBargeForm, approveBargeForm, rejectBargeForm, companyBarges, isBuyer}) => {
  const auction = auctionPayload.auction;
  const auctionState = auctionPayload.status;
  const submittedBarges = auctionPayload.submitted_barges;
  const availableBarges = companyBarges.filter((barge) => {
    return !submittedBarges.find((submittedBarge) => submittedBarge.barge_id == barge.id)
  });

  const buyerBargeApprovalButtons = (auctionBarge) => {
    const barge = auctionBarge.barge;

    return (
      <div>
        <span>{ auctionBarge.approval_status }</span>
        <button onClick={ approveBargeForm.bind(this, auction.id, barge.id) } className={ `button is-primary qa-auction-barge-approve-${barge.id}` }>Approve</button>
        <button onClick={ rejectBargeForm.bind(this, auction.id, barge.id) } className={ `button is-primary qa-auction-barge-reject-${barge.id}` }>Reject</button>
      </div>
    );
  }

  const supplierBargeApprovalStatus = (auctionBarge) => {
    const barge = auctionBarge.barge;

    return (
      <div>
        <span>{ auctionBarge.approval_status }</span>
        <button onClick={ unsubmitBargeForm.bind(this, auction.id, barge.id) } className={ `button is-primary qa-auction-barge-unsubmit-${barge.id}` }>Unsubmit</button>
      </div>
    );
  }

  const renderAvailableBarge = (barge) => {
    return (
      <div className={ `qa-barge-header qa-barge-${barge.id}` } key={ barge.id } >
        <CollapsingBarge
          trigger={ `${barge.name} (${barge.imo_number})` }
          classParentString="collapsing-barge__barge"
          easing="ease"
          open={false}
          submitBargeForm={submitBargeForm}
          unsubmitBargeForm={unsubmitBargeForm}
          approveBargeForm={approveBargeForm}
          rejectBargeForm={rejectBargeForm}
          barge={barge}
          bargeStatus={null}
          isBuyer={isBuyer}
        >
          <div className="collapsing-barge__barge__header">
            <div className="collapsing-barge__barge__content">
              <p><strong>Port</strong> {barge.port}</p>
              <p><strong>Approved for</strong> (Approved for)</p>
              <p><strong>Last SIRE Inspection</strong> ({barge.sire_inspection_date})</p>
              <button onClick={ submitBargeForm.bind(this, auction.id, barge.id) } className={ `button is-primary qa-auction-barge-submit-${barge.id}` }>Submit</button>
            </div>
          </div>
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
          trigger={ `${barge.name} (${barge.imo_number})` }
          classParentString="collapsing-barge__barge"
          easing="ease"
          open={false}
          submitBargeForm={submitBargeForm}
          unsubmitBargeForm={unsubmitBargeForm}
          approveBargeForm={approveBargeForm}
          rejectBargeForm={rejectBargeForm}
          barge={auctionBarge.barge}
          bargeStatus={auctionBarge.approval_status}
          isBuyer={isBuyer}
        >
          <div className="collapsing-barge__barge__header">
            <div className="collapsing-barge__barge__content">
              <p><strong>Port</strong> {barge.port.name}</p>
              <p><strong>Approved for</strong> (Approved for)</p>
              <p><strong>Last SIRE Inspection</strong> ({barge.sire_inspection_date})</p>
              { isBuyer ? buyerBargeApprovalButtons(auctionBarge) : supplierBargeApprovalStatus(auctionBarge) }
            </div>
          </div>
        </CollapsingBarge>
      </div>
    );
  };


  return(
    <div className="box has-margin-bottom-md">
      <div className="box__subsection">
        <h3 className="box__header">Barges for Delivery</h3>
        <form className="auction-barging__container">
          { submittedBarges && submittedBarges.length > 0 && (
            <div className="qa-submitted-barges">
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
