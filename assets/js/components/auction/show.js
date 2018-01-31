import _ from 'lodash';
import React from 'react';
import { formatDateTime } from '../../utilities';

export default class AuctionShow extends React.Component {
  constructor(props) {
    super(props);
  }

  render() {
    const auction =_.filter(this.props.auctions, ['id', window.auctionId]);
    return(<div>
      { auction.map((auction, index) =>
        <div key={index}>
          <section className="auction-page">
            <div className="container">
              <div className = "auction-header__ports has-text-weight-bold" >
                {auction.port.name}
                <span className = "has-text-weight-normal is-inline-block has-padding-left-sm" >
                  ETA { formatDateTime(auction.eta) }
                  GMT & ndash;
                  ETD { formatDateTime(auction.etd) }
                  GMT
                </span>
              </div>
            </div>
          </section>

          <section className="auction-page">
            <div className="container">
              <div className="auction-content">
                <div className="columns is-gapless">
                  <div className="column is-two-thirds">
                    <div className="tabs is-fullwidth is-medium">
                      <ul>
                        <li className="is-active">
                          <h2 className="title is-size-5"><a className="has-text-left">Auction Monitor</a></h2>
                        </li>
                      </ul>
                    </div>
                    <div className="box">
                      <div className="box__subsection">
                        <h3 className="box__header box__header--bordered">Lowest Bid(s)</h3>
                        <table className="table is-fullwidth is-striped">
                          <thead>
                            <tr>
                              <th>Seller</th>
                              <th>{ auction.fuel.name }</th>
                              <th>Unit Price</th>
                              <th>Time</th>
                            </tr>
                          </thead>
                          <tbody>
                            <tr className="is-selected">
                              <td> Seller 2 Seller Name</td>
                              <td> $380.00  Bid per MT of Auctioned Fuel Type</td>
                              <td> $380.00  Total cost per MT for Auctioned Fuel</td>
                              <td> 12:17  Time Bid Was Placed</td>
                            </tr>
                          </tbody>
                        </table>
                      </div>
                      <div className="box__subsection box__subsection--bordered box__subsection--base">
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
                              <input className="input" type="number" step="0.25" name="" value="" id="bid" />
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
                    <div className="box">
                      <h3 className="box__header box__header--bordered">Grade Display</h3>
                      <table className="table is-fullwidth is-striped">
                        <thead>
                          <tr>
                            <th>Seller</th>
                            <th>{ auction.fuel.name }</th>
                            <th>Unit Price</th>
                            <th>Time</th>
                          </tr>
                        </thead>
                        <tbody>
                          <tr className="is-selected">
                            <td> Seller 2 Seller Name</td>
                            <td> $380.00  Bid per MT of Auctioned Fuel Type</td>
                            <td> $380.00  Total cost per MT for Auctioned Fuel</td>
                            <td> 12:17  Time Bid Was Placed</td>
                          </tr>
                          <tr>
                            <td> OceanConnect Marine Seller Name</td>
                            <td> $380.25  Bid per MT of Auctioned Fuel Type</td>
                            <td> $380.25  Total cost per MT for Auctioned Fuel</td>
                            <td> 12:16  Time Bid Was Placed</td>
                          </tr>
                          <tr>
                            <td> OceanConnect Marine Seller Name</td>
                            <td> $380.50  Bid per MT of Auctioned Fuel Type</td>
                            <td> $380.50  Total cost per MT for Auctioned Fuel</td>
                            <td> 12:15  Time Bid Was Placed</td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </div>
                  <div className="column is-one-third">
                    <div className="tabs is-fullwidth is-medium">
                      <ul>
                        <li className="is-active">
                          <h2 className="title is-size-5"><a>Auction Information</a></h2>
                        </li>
                        <li>
                          <h2 className="title is-size-5"><a>Messages</a></h2>
                        </li>
                      </ul>
                    </div>
                    <div className="box">
                      <h3 className="box__header">Invited Suppliers</h3>
                      <ul>
                        <li><span className="icon has-text-success has-margin-right-sm"><i className="fas fa-check-circle"></i></span> Seller #1</li>
                        <li><span className="icon has-text-success has-margin-right-sm"><i className="fas fa-check-circle"></i></span> Seller #2</li>
                        <li><span className="icon has-text-warning has-margin-right-sm"><i className="fas fa-adjust"></i></span> Seller #3</li>
                        <li><span className="icon has-text-danger has-margin-right-sm"><i className="fas fa-times-circle"></i></span> Seller #4</li>
                        <li><span className="icon has-text-dark has-margin-right-sm"><i className="fas fa-question-circle"></i></span> Seller #5</li>
                      </ul>
                    </div>
                    <div className="box">
                      <div className="box__subsection">
                        <h3 className="box__header">Buyer Information</h3>
                        <ul className="list has-no-bullets">
                          <li>
                            <strong>Organization</strong> Company
                          </li>
                          <li>
                            <strong>Buyer</strong> Buyer Name
                          </li>
                          <li>
                            <strong>Buyer Reference Number</strong>  BRN
                          </li>
                        </ul>
                      </div>
                      <div className="box__subsection">
                        <h3 className="box__header">Fuel Requirements</h3>
                        <ul className="list has-no-bullets">
                          <li>
                            <strong>{ auction.fuel.name }</strong> { auction.fuel_quantity } MT
                          </li>
                        </ul>
                      </div>
                      <div className="box__subsection">
                        <h3 className="box__header">Port Information</h3>
                          <ul className="list has-no-bullets">
                            <li>
                              <strong className="is-block">{ auction.port.name }</strong>
                              <span className="is-size-7"><strong>ETA</strong> { formatDateTime(auction.eta) } GMT &ndash; <strong>ETD</strong> { formatDateTime(auction.etd) } GMT</span>
                            </li>
                          </ul>
                      </div>
                      <div className="box__subsection">
                        <h3 className="box__header">Additional Information</h3>
                        <ul className="list has-no-bullets">
                          <li>
                            { auction.additional_information }
                          </li>
                        </ul>
                      </div>
                      <div className="field has-margin-top-md">
                        <a href={`/auctions/${auction.id}/edit`}>Edit</a>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </section>
    </div>)}
  </div>);
  }
}
