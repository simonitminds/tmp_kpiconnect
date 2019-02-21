import _ from 'lodash';
import React from 'react';
import MediaQuery from 'react-responsive';
import CommentsDisplay from './comments-display';

class CommentForm extends React.Component {
  constructor(props) {
    super(props);
    this.commentInput = null;
  }

  submitForm(ev) {
    ev.preventDefault();
    const {auctionPayload, addCommentToSolution} = this.props;
    const {auction} = auctionPayload;
    const comment = this.commentInput.value;
    const formData = {comment: comment}
    addCommentToSolution(auction.id, formData);
    this.commentInput.value = "";
  }

  render() {
    const {auctionPayload, unsubmitComment} = this.props;
    const auctionId = _.get(auctionPayload, 'auction.id');
    const comments = _.get(auctionPayload, 'submitted_comments', []);

    return (
      <React.Fragment>
        <form onSubmit={this.submitForm.bind(this)}>
          <h3 className="auction-comment__title title is-size-6 is-uppercase has-margin-top-sm">Conditions</h3>
          <p className="is-italic has-text-gray-3 has-margin-bottom-md">Specify minimum parcel size, number of day's notice required for vessel and quantity nomination, and if any additional charges may apply.</p>
          <div className="auction-comment__form-body">
            <textarea
              type="text"
              id="comment"
              name="comment"
              data-comment-input
              ref={(e) => this.commentInput = e}
              className="textarea qa-auction-bid-comment">
            </textarea>
          </div>
          <CommentsDisplay comments={comments} auctionId={auctionId} unsubmitComment={unsubmitComment} isSupplier={true} />
          <div className="field is-horizontal is-expanded">
            <div className="field is-expanded is-grouped is-grouped-right has-margin-top-xs has-margin-bottom-sm has-margin-left-auto">
              <div className="control">
                <button type="submit" className="button is-primary has-margin-top-sm qa-auction-comment-submit">Add Conditions</button>
              </div>
            </div>
          </div>
        </form>
      </React.Fragment>
    );
  }
}

export default CommentForm;
