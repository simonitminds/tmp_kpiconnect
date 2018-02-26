import React from 'react';
import _ from 'lodash';

const AuctionInvitation = ({auction}) => {
  return(
    <div>
      <div className="box is-gray-1">
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
      <div className = "box is-success" >
        <h3 className="has-text-weight-bold">
        <span className="icon box__icon-marker is-medium">
          <i className="fas fa-lg fa-check-circle"></i>
        </span>
        You are participating in this auction</h3>
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
      <div className = "box is-danger" >
        <h3 className="has-text-weight-bold">
        <span className="icon box__icon-marker is-medium">
          <i className="fas fa-lg fa-times-circle"></i>
        </span>
        You are not participating in this auction</h3>
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
      <div className = "box is-warning" >
        <h3 className="has-text-weight-bold">
          <span className="icon box__icon-marker is-medium">
            <i className="fas fa-lg fa-adjust"></i>
          </span>
          You might participate in this auction</h3>
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
