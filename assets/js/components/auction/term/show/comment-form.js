import _ from 'lodash';
import React from 'react';
import MediaQuery from 'react-responsive';

class CommentForm extends React.Component {
  constructor(props) {
    super(props);
  }

  submitForm(ev) {
    const element = document.querySelector('#comment');
    ev.preventDefault();
    const {auctionPayload, addCommentToSolution} = this.props;
    const {auction} = auctionPayload;
    const comment = element.dataset.value;
    const formData = {supplierId: this.props.supplierId, comment: comment}
    addCommentToSolution(auction.id, formData);
  }

  render() {
    const {supplierId} = this.props;

    return (
      <MediaQuery query="(min-width: 769px)">
        <form onSubmit={this.submitForm.bind(this)}>
          <h3 className="auction-comment__title title is-size-6 is-uppercase has-margin-top-sm">Conditions</h3>
          <div className="auction-comment__form-body">
            <textarea
              type="text"
              id="comment"
              name="comment"
              data-comment-input
              className="textarea qa-auction-bid-comment">
            </textarea>
          </div>
          <div className="field is-horizontal is-expanded">
            <div className="field is-expanded is-grouped is-grouped-right has-margin-top-xs has-margin-bottom-sm has-margin-left-auto">
              <div className="control">
                <button type="submit" className="button is-primary has-margin-top-sm qa-auction-bid-submit">Add Conditions</button>
              </div>
            </div>
          </div>
        </form>
      </MediaQuery>
    );
  }
}

export default CommentForm;
