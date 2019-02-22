import _ from 'lodash';
import React from 'react';

const SolutionComments = ({solution}) => {
  const bids = _.get(solution, 'bids')
  const comments = _.map(bids, 'comment');

  return(
    <React.Fragment>
      <div className="qa-auction-solution-comments">
        { comments.length > 0
          ? _.map(comments, (comment) => {
              return (
                <div key={`${_.indexOf(comments, comment)}`} className="qa-auction-solution-comment">
                  {comment}
                </div>
              );
            })
          : <div className="auction-table-placeholder has-margin-top-xs has-margin-bottom-sm qa-solution-no-comments">
              <p className="is-italic">No comments have been placed on this offer.</p>
            </div>
        }
      </div>
    </React.Fragment>
  );
}

export default SolutionComments;
