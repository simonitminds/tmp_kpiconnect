import _ from 'lodash';
import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { formatTime } from '../../../../utilities';

const CommentsDisplay = ({comments, auctionId, isSupplier, unsubmitComment}) => {
  const deleteComment = (ev) => {
    ev.preventDefault();
    const commentId = ev.currentTarget.dataset.commentId;
    unsubmitComment(auctionId, commentId);
  }

  return (
    <React.Fragment>
      <div className="qa-auction-solution-comments">
        { comments.length > 0
            ? _.map(comments, (comment) => {
              const content = _.get(comment, 'comment');
              const timeEntered = _.get(comment, 'time_entered');
                return (
                  <div key={comment.id} className="auction-comment__item qa-auction-solution-comment">
                    <span className="is-inline-block qa-auction-solution-comment-content">{content} </span>
                    <span className="is-inline-block has-margin-left-auto qa-auction-solution-comment-time_entered">({formatTime(timeEntered)})</span>
                    { isSupplier &&
                      <span className={`tag auction-comment__revoke-button qa-auction-solution-comment-delete has-margin-left-sm`}
                        onClick={deleteComment}
                        data-comment-id={comment.id} >
                        <FontAwesomeIcon icon="times" />
                      </span>
                    }
                  </div>
                );
              })
            : <div className="auction-comment__item auction-comment__item--empty qa-auction-no-solution-comments">No conditions have been attached to this bid.</div>
        }
      </div>
    </React.Fragment>
  );
};

export default CommentsDisplay;
