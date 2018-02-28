import React from 'react';
import _ from 'lodash';

const AuctionInvitation = ({auction}) => {
  return(
    <div className="auction-invitation qa-auction-invitation-controls">
      <div className="auction-invitation__status box box--bordered-left is-gray-1">
        <h3 className="has-text-weight-bold">Do you intend to participate in the auction?</h3>
        <div className="field has-addons has-margin-top-md">
          <p className="control">
            <a className="button is-success">
              <span>Accept</span>
            </a>
          </p>
          <p className="control">
            <a className="button is-danger">
              <span>Decline</span>
            </a>
          </p>
          <p className="control">
            <a className="button is-gray-3">
              <span>Maybe</span>
            </a>
          </p>
        </div>
      </div>
      <div className = "auction-invitation__status box is-success" >
        <h3 className="has-text-weight-bold is-flex has-margin-bottom-md">
        <span className="icon box__icon-marker is-medium has-margin-top-none">
          <i className="fas fa-lg fa-check-circle"></i>
        </span>
        <span className="is-inline-block">You are participating in this auction</span></h3>
        <div className="field has-margin-top-xs has-margin-left-lg">
          <div className="control">
            <div className="select select--transparent">
              <select>
                <option disabled="disabled" value="">
                  Change Status
                </option>
                <option>Participating</option>
                <option>May Participate</option>
                <option>Not Participating</option>
              </select>
            </div>
          </div>
        </div>
      </div>
      <div className = "auction-invitation__status box is-danger" >
        <h3 className="has-text-weight-bold is-flex has-margin-bottom-md">
        <span className="icon box__icon-marker is-medium has-margin-top-none">
          <i className="fas fa-lg fa-times-circle"></i>
        </span>
        <span className="is-inline-block">You are not participating in this auction</span></h3>
        <div className="field has-margin-top-xs has-margin-left-lg">
          <div className="control">
            <div className="select select--transparent">
              <select>
                <option disabled="disabled" value="">
                  Change Status
                </option>
                <option>Participating</option>
                <option>May Participate</option>
                <option>Not Participating</option>
              </select>
            </div>
          </div>
        </div>
      </div>
      <div className = "auction-invitation__status box is-warning" >
        <h3 className="has-text-weight-bold is-flex has-margin-bottom-md">
          <span className="icon box__icon-marker is-medium has-margin-top-none">
            <i className="fas fa-lg fa-adjust"></i>
          </span>
          <span className="is-inline-block">You might participate in this auction</span></h3>
        <div className="field has-margin-top-xs has-margin-left-lg">
          <div className="control">
            <div className="select select--transparent">
              <select>
                <option disabled="disabled" value="">
                  Change Status
                </option>
                <option>Participating</option>
                <option>May Participate</option>
                <option>Not Participating</option>
              </select>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default AuctionInvitation;
