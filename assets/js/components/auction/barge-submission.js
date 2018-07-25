import React from 'react';
import _ from 'lodash';
import CollapsibleSection from './collapsible-section';

const BargeSubmission = ({auctionPayload, formSubmit, barges}) => {
  const auction = auctionPayload.auction;
  const auctionState = auctionPayload.state.status;

  return(
    <div className="box has-margin-bottom-md">
      <div className="box__subsection">
        <h3 className="box__header">Barges for Delivery</h3>
        <form className="auction-barging__container">
          { barges.map((barge) =>
            <div className="qa-barge-header">
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
          )}
        </form>
      </div>
    </div>
  );
};

export default BargeSubmission;
