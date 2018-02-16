import _ from 'lodash';
import React from 'react';
import { formatGMTDateTime, formatTimeRemaining, timeRemainingCountdown, formatTimeRemainingColor} from '../../utilities';
import moment from 'moment';

export default class AuctionShow extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      timeRemaining: timeRemainingCountdown(props.auction, moment().utc())
    }
  }

  componentDidMount() {
    this.timerID = setInterval(
      () => this.tick(),
      500
    );
  }

  componentWillUnmount() {
    clearInterval(this.timerID);
  }


  tick() {
    this.setState({
      timeRemaining: timeRemainingCountdown(this.props.auction, moment().utc())
    });
  }

  render() {
    const auction = this.props.auction;

    const additionInfoDisplay = (auction) => {
      if (auction.additional_information) {
        return auction.additional_information;
      } else {
        return <i>No additional information provided.</i>;
      }
    }

    return (
      <div>
        <section className="auction-page"> {/* Breadcrumb information */}
          <div className="container has-margin-top-xl">
            <nav className="breadcrumb has-succeeds-separator has-family-header has-text-weight-bold has-padding-top-md" aria-label="breadcrumbs">
              <ul>
                <li><a href="/auctions">Auctions</a></li>
                <li className="is-active"><a href="#" aria-current="page">Auction ({auction.id})</a></li>
              </ul>
            </nav>
          </div>
        </section>
        <section className="auction-page"> {/* Vessel info */}
          <div className="container">
            <div className="has-margin-top-lg">
              <div className="auction-header">
                <div className="columns has-margin-bottom-none">
                  <div className="column">
                    <div className={`auction-header__status auction-header__status--${auction.state.status} tag is-rounded qa-auction-status`} id="time-remaining">
                      {auction.state.status}
                    </div>
                    <div className="auction-header__po is-uppercase">
                      Auction {auction.po}
                    </div>
                    <h1 className="auction-header__vessel title has-text-weight-bold qa-auction-vessel">
                      {auction.vessel.name} <span className="auction-header__vessel__imo">({auction.vessel.imo})</span>
                    </h1>
                  </div>
                  <div className="column">
                    <div className="auction-header__timer has-text-left-mobile">
                      <div className={`auction-timer auction-timer--${formatTimeRemainingColor(auction, this.state.timeRemaining)}`}>
                        <span className="qa-auction-time_remaining" id="time-remaining">
                          {formatTimeRemaining(auction, this.state.timeRemaining)}
                        </span>
                      </div>
                    </div>
                    <div className="auction-header__start-time has-text-left-mobile">
                      <span className="has-text-weight-bold is-uppercase">Started at</span> {formatGMTDateTime(auction.auction_start)} GMT
                    </div>
                    <div className="auction-header__duration has-text-left-mobile">
                      <span className="has-text-weight-bold is-uppercase">Decision Period</span> {auction.decision_duration} minutes
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section> {/* Vessel info */}

          <section className="auction-page"> {/* Port selection */}
            <div className="container">
              <div className="auction-header__ports has-text-weight-bold">
                <span className="qa-auction-port">{auction.port.name}</span>
                <span className="has-text-weight-normal is-inline-block has-padding-left-sm"> ETA {formatGMTDateTime(auction.eta)} GMT &ndash; ETD {formatGMTDateTime(auction.etd)} GMT</span>
              </div>
            </div>
          </section> {/* Port selection */}

          <section className="auction-page"> {/* Auction details */}
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
                              <th>{auction.fuel.name}</th>
                              <th>Unit Price</th>
                              <th>Time</th>
                            </tr>
                          </thead>
                          <tbody>
                            <tr className="is-selected">
                              <td> Seller 2</td>
                              <td> $380.00</td>
                              <td> $380.00</td>
                              <td> 12:17</td>
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
                    <div className="box">
                      <h3 className="box__header box__header--bordered">Grade Display</h3>
                      <table className="table is-fullwidth is-striped">
                        <thead>
                          <tr>
                            <th>Seller</th>
                            <th>{auction.fuel.name}</th>
                            <th>Unit Price</th>
                            <th>Time</th>
                          </tr>
                        </thead>
                        <tbody>
                          <tr className="is-selected">
                            <td> Seller 2</td>
                            <td> $380.00</td>
                            <td> $380.00</td>
                            <td> 12:17</td>
                          </tr>
                          <tr>
                            <td> OceanConnect Marine</td>
                            <td> $380.25</td>
                            <td> $380.25</td>
                            <td> 12:16</td>
                          </tr>
                          <tr>
                            <td> OceanConnect Marine</td>
                            <td> $380.50</td>
                            <td> $380.50</td>
                            <td> 12:15</td>
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
                        <li><span className="icon has-text-success has-margin-right-sm"><i className="fas fa-check-circle"></i></span>Seller #1</li>
                        <li><span className="icon has-text-success has-margin-right-sm"><i className="fas fa-check-circle"></i></span>Seller #2</li>
                        <li><span className="icon has-text-warning has-margin-right-sm"><i className="fas fa-adjust"></i></span>Seller #3</li>
                        <li><span className="icon has-text-danger has-margin-right-sm"><i className="fas fa-times-circle"></i></span>Seller #4</li>
                        <li><span className="icon has-text-dark has-margin-right-sm"><i className="fas fa-question-circle"></i></span>Seller #5</li>
                      </ul>
                    </div>
                    <div className="box">
                      <div className="box__subsection">
                        <h3 className="box__header">Buyer Information</h3>
                        <ul className="list has-no-bullets">
                          <li>
                            <strong>Organization</strong> {auction.buyer.company.name}
                          </li>
                          <li>
                            <strong>Buyer</strong> Buyer Name
                          </li>
                          <li>
                            <strong>Buyer Reference Number</strong> BRN
                          </li>
                        </ul>
                      </div>
                      <div className="box__subsection">
                        <h3 className="box__header">Fuel Requirements</h3>
                        <ul className="list has-no-bullets">
                          <li>
                            <strong>{auction.fuel.name}</strong> {auction.fuel_quantity} MT
                          </li>
                        </ul>
                      </div>
                      <div className="box__subsection">
                        <h3 className="box__header">Port Information</h3>
                        <ul className="list has-no-bullets">
                          <li>
                            <strong className="is-block">{auction.port.name}</strong>
                            <span className="is-size-7"><strong>ETA</strong> {formatGMTDateTime(auction.eta)} GMT &ndash; <strong>ETD</strong> {formatGMTDateTime(auction.etd)} GMT</span>
                          </li>
                        </ul>
                      </div>
                      <div className="box__subsection">
                        <h3 className="box__header">Additional Information</h3>
                        <ul className="list has-no-bullets">
                          <li>
                            {additionInfoDisplay(auction)}
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
          </section> {/* Auction details */}
      </div>
    );
  }
}
