import React from 'react';
import _ from 'lodash';

const SolutionComment = ({bid, showInput, auctionStatus, solutionComment}) => {
  if (auctionStatus == "closed" && solutionComment) {
    return (
      <div className="auction-comment box box--nested-base box--best-solution-comment box--best-solution-comment--completed is-gray-1 has-padding-top-md">
        <h3 className="has-text-weight-bold has-margin-bottom-sm">Comment from the Buyer:</h3>
        <p className="qa-bid-comment">{solutionComment}</p>
      </div>
    )
  } else if (showInput) {
    return(
      <div className="has-margin-bottom-md">
        <div className="field is-expanded">
          <div className="field-label">
            <div className="control">
              <label className="label has-text-weight-normal has-margin-bottom-sm" htmlFor="bid"><i>Why did you select this offer? (A response is not required, but is suggested)</i></label>
            </div>
          </div>
          <div className="field-body">
            <div className="control is-expanded">
              <textarea name="comment" className="textarea qa-solution-comment"/>
            </div>
          </div>
        </div>
      </div>
    );
  } else {
    return <div className="auction-comment qa-bid-comment"></div>;
  }
};
export default SolutionComment;
