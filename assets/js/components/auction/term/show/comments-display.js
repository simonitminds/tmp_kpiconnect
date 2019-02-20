import _ from 'lodash';
import React from 'react';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { formatTime } from '../../../../utilities';

const CommentsDisplay = ({auctionPayload, unsubmitComment}) => {
  const deleteComment = (ev) => {
    ev.preventDefault();
    const auctionId = _.get(auctionPayload, 'auction.id');
    const commentId = ev.currentTarget.dataset.commentId;
    unsubmitComment(auctionId, commentId);
  }

  const auctionId = _.get(auctionPayload, 'auction.id');
  const comments = _.get(auctionPayload, 'submitted_comments', []);
  return (
    <React.Fragment>
      <div className="qa-auction-solution-comments">
        { comments.length > 0
            ? _.map(comments, (comment) => {
              const content = _.get(comment, 'comment');
              const timeEntered = _.get(comment, 'time_entered');
                return (
                  <div key={comment.id} className="qa-auction-solution-comment">
                    <span className="qa-auction-solution-comment-content">{content} </span>
                    <span className="qa-auction-solution-comment-time_entered">({formatTime(timeEntered)})</span>
                    <span className={`tag delete-comment__button qa-auction-solution-comment-${comment.id}-delete has-margin-left-sm`}
                      onClick={deleteComment}
                      data-comment-id={comment.id} >
                      <FontAwesomeIcon icon="times" />
                    </span>
                  </div>
                );
              })
            : <span className="qa-auction-no-solution-comments"></span>
        }
      </div>
    </React.Fragment>
  );
};

export default CommentsDisplay;
