import React from 'react';
import _ from 'lodash';
import InputField from '../input-field';
import SolutionComment from './solution-comment';

const SolutionAcceptDisplay = ({bidIds, auctionPayload, bestSolutionSelected, acceptSolution, cancelSelection}) => {
  const auctionStatus = auctionPayload.status;
  if(auctionStatus == 'closed'){
    return "";
  } else {
    return (
        <form className="auction-solution__confirmation box box--nested-base box--nested-base--extra-nested box--best-solution-comment is-gray-1 has-padding-top-md" onSubmit={acceptSolution}>
        { bestSolutionSelected ?
        "" :
        <span className="is-inline-block has-margin-bottom-lg"><strong>Are you sure that you want to accept this offer?</strong></span>
        }

        <SolutionComment showInput={!bestSolutionSelected} auctionStatus={auctionStatus} />

        <div className="has-margin-top-md has-margin-bottom-sm"><i>Optional: Specify the Port Agent handling delivery</i></div>
        <InputField
          model={'auction'}
          field={'port_agent'}
          labelText={'Port Agent'}
          value={auctionPayload.auction.port_agent}
          expandedInput={true}
          opts={{ labelClass: 'label is-capitalized has-text-left has-margin-bottom-xs' }}
        />
        <div className="field is-expanded is-grouped is-grouped-right">
          <div className="control">
            <button className="button is-gray-3" onClick={cancelSelection}>
              Cancel
            </button>
          </div>
          <div className="control">
              <button
                disabled={auctionPayload.status != 'decision'}
                className={`button is-success qa-accept-bid`}
                type="submit"
              >
                Accept Offer
              </button>
          </div>
        </div>
      </form>
    );
  }
}
export default SolutionAcceptDisplay;
