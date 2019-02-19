import _ from 'lodash';
import React from 'react';
import MediaQuery from 'react-responsive';

class ConditionsForm extends React.Component {

  submitForm(ev) {
    ev.preventDefault();
    const {auctionPayload, formSubmit} = this.props;
    const {auction} = auctionPayload;
    const formData = {condition: ev.targets.elements.dataset.conditionInput}
    formSubmit(auction.id, formData);
  }

  render() {
    const {auctionPayload, supplierId} = this.props;
    const auction = _.get(auctionPayload, 'auction');
    const auctionStatus = _.get(auctionPayload, 'status');

    return (
      <div className={`auction-bidding ${auctionStatus == 'pending'? `auction-bidding--pending` : ``} box box--nested-base`}>
        <MediaQuery query="(min-width: 769px)">
          <form onSubmit={this.submitForm.bind(this)}>
            <h3 className="auction-condition__title title is-size-6 is-uppercase has-margin-top-sm">Conditions</h3>
            <div className="auction-condition__form-body">
              <textarea
                id="condition"
                data-condition-input
                className="textarea qa-auction-condition">
              </textarea>
            </div>
            <div className="field is-horizontal is-expanded">
              <div className="field is-expanded is-grouped is-grouped-right has-margin-top-xs has-margin-bottom-sm has-margin-left-auto">
                <div className="control">
                  <button type="submit" className="button is-primary has-margin-top-sm qa-auction-condition-submit">Add Conditions</button>
                </div>
              </div>
            </div>
          </form>
        </MediaQuery>
      </div>
    );
  }
};
