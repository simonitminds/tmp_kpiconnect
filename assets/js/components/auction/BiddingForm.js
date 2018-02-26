import React from 'react';
import _ from 'lodash';

const BiddingForm = ({auction}) => {
  const fuel = _.get(auction, 'fuel.name');
  return(
    <div className="box">
      <h3 className="box__header box__header--bordered">Your Most Recent Bid</h3>
      <table className="table is-fullwidth is-striped is-marginless">
        <thead>
          <tr>
            <th>{fuel}</th>
            <th>Unit Price</th>
            <th>Time</th>
          </tr>
        </thead>
        <tbody>
          <tr className="is-gray-1">
            <td> $380.00</td>
            <td> $380.00</td>
            <td> 12:17</td>
          </tr>
        </tbody>
      </table>
      <h3 className="box__header box__header--bordered">Your Minimum Bid</h3>
      <table className="table is-fullwidth is-striped is-marginless">
        <thead>
          <tr>
            <th>{fuel}</th>
            <th>Unit Price</th>
            <th>Time</th>
          </tr>
        </thead>
        <tbody>
          <tr className="is-gray-1">
            <td> $380.00</td>
            <td> $380.00</td>
            <td> 12:12</td>
          </tr>
        </tbody>
      </table>

      <div className="box__subsection box__subsection--bordered box__subsection--base is-gray-1">
        <h3 className="title is-size-6 is-uppercase has-margin-top-sm">Place Bid</h3>
        <div className="field is-horizontal is-expanded">
          <div className="field-label">
            <div className="control">
              <label className="label" htmlFor="fuel_type">Fuel Type</label>
            </div>
          </div>
          <div className="field-body">
            <div className="control is-expanded">
              <div className="select is-fullwidth">
                <select className="" name="" id="fuel_type">
                  <option value="">Fuel Type</option>
                </select>
              </div>
            </div>
          </div>
        </div>
        <div className="field is-horizontal is-expanded">
          <div className="field-label">
            <div className="control">
              <label className="label" htmlFor="bid">Bid Amount</label>
            </div>
          </div>
          <div className="field-body">
            <div className="control is-expanded has-icons-left">
              <input className="input" type="number" id="bid" step="0.25" name="" value="" />
              <span className="icon is-small is-left">
                <i className="fas fa-dollar-sign"></i>
              </span>
            </div>
          </div>
        </div>
        <div className="field is-horizontal is-expanded">
          <div className="field-label">
            <div className="control">
              <label className="label" htmlFor="bid">Minimum Bid</label>
            </div>
          </div>
          <div className="field-body">
            <div className="control is-expanded has-icons-left">
              <input className="input" type="number" id="minimumBid" step="0.25" name="" value="" />
              <span className="icon is-small is-left">
                <i className="fas fa-dollar-sign"></i>
              </span>
            </div>
          </div>
        </div>
        <div className="field is-horizontal is-expanded">
          <div className="field-label">
            <div className="control">
              <label className="label" htmlFor="expiration">Expiration</label>
            </div>
          </div>
          <div className="field-body">
            <div className="control is-expanded">
              <div className="select is-fullwidth">
                <select className="" name="" id="expiration">
                  <option value="">Bid Expiration</option>
                </select>
              </div>
            </div>
          </div>
        </div>
        <div className="field is-horizontal is-expanded">
          <div className="field-label">
            <div className="control">
              <label className="label" htmlFor="terms">Credit Terms</label>
            </div>
          </div>
          <div className="field-body">
            <div className="control is-expanded">
              <div className="select is-fullwidth">
                <select className="" name="" id="terms">
                  <option value="">Credit Terms</option>
                </select>
              </div>
            </div>
          </div>
        </div>
        <div className="field is-expanded is-grouped is-grouped-right has-margin-top-xs has-margin-bottom-sm">
          <div className="control">
            <button type="button" className="button is-primary">Place Bid</button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default BiddingForm;
