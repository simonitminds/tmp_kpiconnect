import React from 'react';
import _ from 'lodash';
import CollapsibleSection from './collapsible-section';

const BargeSubmission = ({auctionPayload, formSubmit}) => {
  const auction = auctionPayload.auction;
  const auctionState = auctionPayload.status;
  const availableBarges = auctionPayload.available_barges;
  const submittedBarges = auctionPayload.submitted_barges;

  const renderAvailableBarge = (barge) => {
    return (
      <div className={ `qa-barge-header qa-barge-${barge.id}` } key={ barge.id }>
        <CollapsibleSection
          trigger={ `${barge.name} (${barge.imo_number})` }
          classParentString="auction-barging__barge"
          easing="ease"
          open={false}
        >
          <div className="auction-barging__barge__header">
            <div className="auction-barging__barge__content">
              <p><strong>Port</strong> {barge.port}</p>
              <p><strong>Approved for</strong> (Approved for)</p>
              <p><strong>Last SIRE Inspection</strong> ({barge.sire_inspection_date})</p>
              <button className={ `button is-primary qa-auction-barge-submit-${barge.id}` }>Submit</button>
            </div>
          </div>
        </CollapsibleSection>
      </div>
    );
  };

  const renderSubmittedBarge = (barge) => {
    return (
      <div className={ `qa-barge-header qa-barge-${barge.id}` } key={ barge.id }>
        <CollapsibleSection
          trigger={ `${barge.name} (${barge.imo_number})` }
          classParentString="auction-barging__barge"
          easing="ease"
          open={false}
        >
          <div className="auction-barging__barge__header">
            <div className="auction-barging__barge__content">
              <p><strong>Port</strong> {barge.port}</p>
              <p><strong>Approved for</strong> (Approved for)</p>
              <p><strong>Last SIRE Inspection</strong> ({barge.sire_inspection_date})</p>
            </div>
          </div>
        </CollapsibleSection>
      </div>
    );
  };


  return(
    <div className="box has-margin-bottom-md">
      <div className="box__subsection">
        <h3 className="box__header">Barges for Delivery</h3>
        <form className="auction-barging__container">
          <strong>Submitted Barges</strong>
          <div className="qa-submitted-barges">
            { submittedBarges.map(renderSubmittedBarge) }
          </div>

          <strong>Available Barges</strong>
          <div className="qa-available-barges">
            { availableBarges.map(renderAvailableBarge) }
          </div>
        </form>
      </div>
    </div>
  );
};

export default BargeSubmission;
